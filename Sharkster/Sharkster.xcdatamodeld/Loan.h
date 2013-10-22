/*
     File: Loan.h
 Abstract: Represents the Loan entity in our data model.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import <CoreData/CoreData.h>
typedef enum {
    LoanLength3Days     = 0,
    LoanLength1Week     = 1,
    LoanLength2Weeks    = 2,
    LoanLength3Weeks    = 3,
    LoanLength1Month    = 4,
    LoanLength3Months   = 5,
    LoanLength6Months   = 6,
    LoanLength9Months   = 7,
    LoanLength1Year     = 8,
    LoanLength2Years    = 9,
    LoanLength3Years    = 10
} LoanLengths;

typedef enum {
    LoanPaymentFrequencyDaily       = 0,
    LoanPaymentFrequency3Days       = 1,
    LoanPaymentFrequencyWeekly      = 2,
    LoanPaymentFrequencyBiweekly    = 3,
    LoanPaymentFrequencyMonthly     = 4,
    LoanPaymentFrequency3Months     = 5,
    LoanPaymentFrequency6Months     = 6,
    LoanPaymentFrequencyYearly      = 7
} LoanPaymentFrequency;


@class Payment;

@interface Loan :  NSManagedObject  
//CoreData backed properties
@property (nonatomic, retain) NSNumber * principal;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * personID;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * interestRate;
@property (nonatomic, retain) NSSet * payments;
@property (nonatomic, retain) NSNumber * paymentFrequency;

//Calculated properties (some of these are expensive)
@property (nonatomic, readonly) NSNumber * totalAmount;
@property (nonatomic, readonly) NSNumber * interest;
@property (nonatomic, readonly) NSDate * endDate;
@property (nonatomic, readonly) NSArray * orderedPayments;
@property (nonatomic, readonly) NSArray * paymentsSortedByDate;
@property (nonatomic, readonly) Payment * nextPayment;

//These are calculated manually using NSCalendar, and aren't guaranteed 
//to match EventKit's recurrence scheduling
- (NSDate *)expectedDateForPaymentNumber:(int)paymentNumber;
- (int)expectedNumberOfPayments;

- (NSString *)paymentAmountForNumberOfPayments:(int)numberOfPayments;
- (NSString *)lastPaymentAmountForNumberOfPayments:(int)numberOfPayments;
- (BOOL)hasDifferentLastPaymentForNumberOfPayments:(int)numberOfPayments;
@end

@interface Loan (CoreDataGeneratedAccessors)
- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet *)value;
- (void)removePayments:(NSSet *)value;

@end

