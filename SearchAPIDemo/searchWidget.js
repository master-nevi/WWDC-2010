/********************************************************************************************************
 * searchWidget.js
 * Sample Code to provide a live searchWidget for iTunes Content.
 *******************************************************************************************************/ 
 /*
     File: searchWidget.js
 Abstract: Javascript code for accessing the iTunes Store Search API and handling its results.
  Version: 1.0
 
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

function htmlElementForJsonElement(item) {
    var result = $("<div/>").addClass("itmsSearchResult");

    var contentLink = $("<a/>");
    var url = (item.collectionViewUrl) ? item.collectionViewUrl : item.trackViewUrl;
    url = affiliate.affiliatedUrlForUrl(url, partnerId, urlPrefix),
    contentLink.attr("href", url);
    
    var contentTitle = (null != item.collectionCensoredName) ? item.collectionCensoredName : item.trackCensoredName;
    if (null != item.collectionCensoredName && null != item.trackCensoredName) { contentTitle += " - " + item.trackCensoredName; }
    contentLink.attr("title", contentTitle);

    var img = contentLink.clone().addClass("itmsSearchResultImgLink");
    img.append($("<img/>").attr("src", item.artworkUrl100));
    result.append(img);

    var resultText = $("<div/>").addClass("itmsSearchResultText");
    var artistText = $("<div/>");
    var contentText = $("<div/>");;
    if (null != item.artistName) { 
        var artistWrapper = (null != item.artistViewUrl) ? $("<a/>").attr("href", item.artistViewUrl) : $("<span/>");
        artistText.append(artistWrapper.text(item.artistName));
    }
    contentText.append(contentLink.clone().text(contentLink.attr("title")));
    resultText.append(artistText).append(contentText);

    result.append(resultText);    
    result.hover(
        function () { $(this).find("a.itmsSearchResultImgLink").show(); },
          function () { $(this).find("a.itmsSearchResultImgLink").hide(); });
     return result;
  }

/** search for the terms entered in the search field box and display results */
function doSearch(){
    var query = $("#itmsSearch").serialize() + "&limit=50&country=US";
    var url = "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/wsSearch?" + query + "&callback=?";

//    $.debug("URL: " + url);
    $.getJSON(url, function(data) {
      $("#itmsSearchResults").empty().hide();

      var collectionIdHashMap = {}; // this allows us to limit output to 1 row per album
      var numRows = 0; // the number of rows we've actually displayed so far
      $.each(data.results, function(inputRowIndex, item){
        if (10 == numRows) { return false; } // break out of the $.each function
        var collectionId = item.collectionId;
        if (null != collectionId) {
            if (null != collectionIdHashMap[collectionId]) return true; // ie, "continue" the $.each, skip this element.
            collectionIdHashMap[collectionId] = 1;
        }
        var newRow = htmlElementForJsonElement(item);
        if (0 == (numRows % 2)) { newRow.css("background-color", "#fff"); } else { newRow.css("background-color", "#edf3fe"); }
        numRows++;
        $("#itmsSearchResults").append(newRow);
      });
    
      $("#itmsSearchResults").show(1400);
      $("#itmsSearchWidgetFooter").show(1);
      $("#itmsSearchWidgetFooter").find("a").attr("href", "http://itunes.apple.com/WebObjects/MZSearch.woa/wa/search?" + $("#itmsSearch").serialize());
    });
    return false;
  }

