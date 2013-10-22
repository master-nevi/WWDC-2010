/********************************************************************************************************
 * rssFeed.js
 * Sample Code to Access an iTunes RSS feed and display on a website.
 *******************************************************************************************************/ 
 /*
     File: rssFeed.js
 Abstract: Javascript code consuming Atom feeds from the iTunes Store
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


if (!window['rss']) { window['rss'] = {}; }

/** @return a simple array of objects containing artworkUrl, id, title, artistName, and artistId */
rss.getSimplifiedFeed = function getSimplifiedFeed(feedUrl, partnerId, urlPrefix, entryTransformFunction, callback) {
    $.getJSON(feedUrl, null, function(data) {
    try {
      console.debug("Raw data:", data);
      var result = [];

      if (!data.feed.entry) {
        console.warn("No 'entry' array for feed:", url);
      } else {

        // iterate over each RSS entry:
        $.each(data.feed.entry, function(i, rssEntry) {
          try {
            console.group("Entry " + i + ": " + rssEntry['im:name'].label, rssEntry);
            console.debug(rssEntry);
            var simpleEntry = {
              "url" : affiliate.affiliatedUrlForUrl($.getObject( "id.label", rssEntry ), partnerId, urlPrefix),
              "id" : $.getObject( "id.label", rssEntry ).replace(/.*\/id(\d+)(\?.*|$)/, '$1'),
              "artworkUrl" : $.getObject( "im:image.2.label", rssEntry ),
              "title" : $.getObject( "title.label", rssEntry ),
              "contentTitle" : $.getObject( "im:name.label", rssEntry ),
              "artistName" : $.getObject( "im:artist.label", rssEntry ),
              "artistId" : $.getObject( "im:artist.attributes.href", rssEntry ).replace(/.*\/id(\d+)(\?.*|$)/, '$1')
            };

            result.push(entryTransformFunction(simpleEntry));           
            console.groupEnd();
          } catch(e) { console.warn("Caught exception", e, rssEntry); }
        });
      }
    } catch(e) { console.warn("Caught exception", e); }
    callback(result);
  });
}

/** @return an HTML element for a given entry, including data from a quick SearchAPI lookup for the top songs on the album. */
rss.htmlElementForSimpleFeedEntry = function htmlElementForSimpleFeedEntry(simpleEntry) {
  var result = $("<div/>").addClass('rssResult');
  var contentLink = $("<a/>").addClass("rssLinkedImage");
  contentLink.attr("href", simpleEntry.url);
  contentLink.attr("title", simpleEntry.title);
  contentLink.append($("<img/>").attr("src", simpleEntry.artworkUrl));
  contentLink.data('id', simpleEntry.id);
  result.append(contentLink);

  if (true) {
    var overlay = $("<ol/>").addClass('songOverlay');
    var url = 'http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/wsLookup?entity=song&limit=5&sort=popularity&id=' + simpleEntry.id;
    $.getJSON(url, null, function(data) {
      $.each(data.results, function(index, song) {
        if (index == 0) { return true; } // skip the first entry, which will be for the album
        overlay.append($("<li/>").text(song.trackCensoredName));
      });
      result.append(overlay);
    });
  }
  return result;  
}
  
