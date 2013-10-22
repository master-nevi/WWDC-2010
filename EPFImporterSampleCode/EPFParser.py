#
# File: EPFParser.py
# Abstract: The EPFParser.py module reads data from EPF data files and converts it into a form suitable for the EPFIngester.
# Version: 1.0
# 
# Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
# Inc. ("Apple") in consideration of your agreement to the following
# terms, and your use, installation, modification or redistribution of
# this Apple software constitutes acceptance of these terms.  If you do
# not agree with these terms, please do not use, install, modify or
# redistribute this Apple software.
# 
# In consideration of your agreement to abide by the following terms, and
# subject to these terms, Apple grants you a personal, non-exclusive
# license, under Apple's copyrights in this original Apple software (the
# "Apple Software"), to use, reproduce, modify and redistribute the Apple
# Software, with or without modifications, in source and/or binary forms;
# provided that if you redistribute the Apple Software in its entirety and
# without modifications, you must retain this notice and the following
# text and disclaimers in all such redistributions of the Apple Software.
# Neither the name, trademarks, service marks or logos of Apple Inc. may
# be used to endorse or promote products derived from the Apple Software
# without specific prior written permission from Apple.  Except as
# expressly stated in this notice, no other rights or licenses, express or
# implied, are granted by Apple herein, including but not limited to any
# patent rights that may be infringed by your derivative works or by other
# works in which the Apple Software may be incorporated.
# 
# The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
# MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
# OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
# 
# IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
# MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
# AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#  
# Copyright (C) 2010 Apple Inc. All Rights Reserved.
#

import os
import re
import logging

LOGGER = logging.getLogger()


class SubstringNotFoundException(Exception):
    """
    Exception thrown when a comment character or other tag is not found in a situation where it's required.
    """
    

class Parser(object):
    """
    Parses an EPF file.
    
    During initialization, all the file db metadata is stored, and the
    file seek position is set to the beginning of the first data record.
    The Parser object can then be used directly by an Ingester to create
    and populate the table.
    
    typeMap is a dictionary mapping datatype strings in the file to corresponding
    types for the database being used. The default map is for MySQL.
    """
    commentChar = "#"
    recordDelim = "\x02\n"
    fieldDelim = "\x01"
    primaryKeyTag = "primaryKey:"
    dataTypesTag = "dbTypes:"
    exportModeTag = "exportMode:"
    recordCountTag = "recordsWritten:"

    def __init__(self, filePath, typeMap={"CLOB":"LONGTEXT"}, recordDelim='\x02\n', fieldDelim='\x01'):
        self.dataTypeMap = typeMap
        self.numberTypes = ["INTEGER", "INT", "BIGINT", "TINYINT"]
        self.dateTypes = ["DATE", "DATETIME", "TIME", "TIMESTAMP"]
        self.columnNames = []
        self.primaryKey = []
        self.dataTypes = []
        self.exportMode = None
        self.dateColumns = [] #fields containing dates need special treatment; we'll cache the indexes here
        self.numberColumns = [] #numeric fields don't accept NULL; we'll cache the indexes here to use later
        self.typeMap = None
        self.recordsExpected = 0
        self.latestRecordNum = 0
        self.commentChar = Parser.commentChar
        self.recordDelim = recordDelim
        self.fieldDelim = fieldDelim
        
        self.eFile = open(filePath, mode="rU") #this will throw an exception if filePath does not exist
        
        #Seek to the end and parse the recordsWritten line
        self.eFile.seek(-40, os.SEEK_END)
        str = self.eFile.read() #reads from -40 to end of file
        lst = str.split(self.commentChar + Parser.recordCountTag)
        numStr = lst.pop().rpartition(self.recordDelim)[0]
        self.recordsExpected = int(numStr)
        self.eFile.seek(0, os.SEEK_SET) #seek back to the beginning
        #Extract the column names
        line1 = self.nextRowString(ignoreComments=False)
        self.columnNames = self.splitRow(line1, requiredPrefix=self.commentChar)
        
        #We'll now grab the rest of the header data, without assuming a particular order
        primStart = self.commentChar+Parser.primaryKeyTag
        dtStart = self.commentChar+Parser.dataTypesTag
        exStart = self.commentChar+Parser.exportModeTag
        
        #Grab the next 6 lines, which should include all the header comments
        firstRows=[]
        for j in range(6):
            firstRows.append(self.nextRowString(ignoreComments=False))
            firstRows = [aRow for aRow in firstRows if aRow] #strip None rows (possible if the file is < 6 rows)
        
        #Loop through the rows, extracting the header info
        for aRow in firstRows:
            if aRow.startswith(primStart):
                self.primaryKey = self.splitRow(aRow, requiredPrefix=primStart)
                self.primaryKey = ([] if self.primaryKey == [''] else self.primaryKey)
            elif aRow.startswith(dtStart):
                self.dataTypes = self.splitRow(aRow, requiredPrefix=dtStart)
            elif aRow.startswith(exStart):
                self.exportMode = self.splitRow(aRow, requiredPrefix=exStart)[0]
        """        
        #Extract the primary key (a list, since it may be a compound key)
        line2 = self.nextRowString(ignoreComments=False)
        self.primaryKey = self.splitRow(line2, requiredPrefix=self.commentChar+Parser.primaryKeyTag)
        #Extract the datatypes
        line3 = self.nextRowString(ignoreComments=False)
        self.dataTypes = self.splitRow(line3, requiredPrefix=self.commentChar+Parser.dataTypesTag)
        """
        self.eFile.seek(0, os.SEEK_SET) #seek back to the beginning

        #Convert any datatypes to mapped counterparts, and cache indexes of date/time types and number types
        for j in range(len(self.dataTypes)):
            dType = self.dataTypes[j]
            if self.dataTypeMap.has_key(dType):
                self.dataTypes[j] = self.dataTypeMap[dType]
            if dType in self.dateTypes:
                self.dateColumns.append(j)
            if dType in self.numberTypes:
                self.numberColumns.append(j)
        #Build a dictionary of column names to data types
        self.typeMap = dict(zip(self.columnNames, self.dataTypes))
        
    
    def setSeekPos(self, pos=0):
        """
        Sets the underlying file's seek position.
        
        This is useful for resuming a partial ingest that was interrupted for some reason.
        """
        self.eFile.seek(pos)
 
    
    def getSeekPos(self):
        """
        Gets the underlying file's seek position.
        """
        return self.eFile.tell()
        
    seekPos = property(fget=getSeekPos, fset=setSeekPos, doc="Seek position of the underlying file")
    

    def seekToRecord(self, recordNum):
        """
        Set the seek position to the beginning of the recordNumth record.
        
        Seeks to the beginning of the file if recordNum <=0,
        or the end if it's greater than the number of records.
        """
        self.seekPos = 0
        self.latestRecordNum = 0
        if (recordNum <= 0):
            return
        for j in range(recordNum):
            self.advanceToNextRecord()

            
    def nextRowString(self, ignoreComments=True):
        """
        Returns (as a string) the next row of data (as delimited by self.recordDelim),
        ignoring comments if ignoreComments is True.
        
        Leaves the delimiters in place.
        
        Unfortunately Python doesn't allow line-based reading with user-supplied line separators
        (http://bugs.python.org/issue1152248), so we use normal line reading and then concatenate
        when we hit 0x02.
        """
        lst = []
        isFirstLine = True
        while (True):
            ln = self.eFile.readline()
            if (not ln): #end of file
                break
            #Although EPF specifies its exports as utf-8, for some reason Python sometimes complains
            #about out-of-ASCII characters unless we reencode as latin-1.
            ln = unicode(ln, 'latin-1')
            if (isFirstLine and ignoreComments and ln.find(self.commentChar) == 0): #comment
                continue
            lst.append(ln)
            if isFirstLine:
                isFirstLine = False
            if (ln.find(self.recordDelim) != -1): #last textual line of this record
                break
        if (len(lst) == 0):
            return None
        else:
            rowString = "".join(lst) #concatenate the lines into a single string, which is the full content of the row
            return rowString
            
            
    def advanceToNextRecord(self):
        """
        Performs essentially the same task as nextRowString, but without constructing or returning anything.
        This allows much faster access to a record in the middle of the file.
        """
        while (True):
            ln = self.eFile.readline()
            if (not ln): #end of file
                return
            if (ln.find(self.commentChar) == 0): #comment; always skip
                continue
            if (ln.find(self.recordDelim) != -1): #last textual line of this record
                break
        self.latestRecordNum += 1
        
   
    def splitRow(self, rowString, requiredPrefix=None):
        """
        Given rowString, strips requiredPrefix and self.recordDelim,
        then splits on self.fieldDelim, returning the resulting list.
        
        If requiredPrefix is not present in the row, throws a SubstringNotFound exception
        """
        if (requiredPrefix):
            ix = rowString.find(requiredPrefix)
            if (ix != 0):
                expl = "Required prefix '%s' was not found in '%s'" % (requiredPrefix, rowString)
                raise SubstringNotFoundException, expl
            rowString = rowString.partition(requiredPrefix)[2]
        str = rowString.partition(self.recordDelim)[0]
        return str.split(self.fieldDelim)

    
    def nextRecord(self):
        """
        Returns the next row of data as a list, or None if we're out of data.
        """
        rowString = self.nextRowString()
        if (rowString):
            self.latestRecordNum += 1 #update the record counter
            rec = self.splitRow(rowString)
            rec = rec[:len(self.columnNames)] #if there are more data records than column names,
            #trim any surplus records via a slice
            
            #replace empty strings with NULL
            for i in range(len(rec)):
                val = rec[i]
                rec[i] = ("NULL" if val == "" else val)

            #massage dates into MySQL-compatible format.
            #most date values look like '2009 06 21'; some are '2005-09-06-00:00:00-Etc/GMT'
            #there are also some cases where there's only a year; we'll pad it out with a bogus month/day
            yearMatch = re.compile(r"^\d\d\d\d$")
            for j in self.dateColumns:
                rec[j] = rec[j].strip().replace(" ", "-")[:19] #Include at most the first 19 chars
                if yearMatch.match(rec[j]):
                     rec[j] = "%s-01-01" % rec[j]
            return rec
        else:
            return None
                
        
    def nextRecords(self, maxNum=100):
        """
        Returns the next maxNum records (or fewer if EOF) as a list of lists.
        """
        records = []
        for j in range(maxNum):
            lst = self.nextRecord()
            if (not lst):
                break
            records.append(lst)
        return records
                
        
    def nextRecordDict(self):
        """
        Returns the next row of data as a dictionary, keyed by the column names.
        """
        vals = self.nextRecord()
        if (not vals):
            return None
        else:
            keys = self.columnNames
            return dict(zip(keys, vals))

