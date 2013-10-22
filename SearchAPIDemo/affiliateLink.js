/*
    File: affiliateLink.js
Abstract: Javascript code for handling and creating affiliated URLs
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

if (!window['affiliate']) { window['affiliate'] = {}; }


// a private mapping of different query params available for a given affiliate network
affiliate._queryParamsByPartnerId = {
	30   : { "urlPrefixQueryParam" : "LS_PARAM",  "affiliateTokenQueryParam" : "siteID" },
	2003 : { "urlPrefixQueryParam" : "TD_PARAM",  "affiliateTokenQueryParam" : "tduid" },
	1002 : { "urlPrefixQueryParam" : "AFF_PARAM", "affiliateTokenQueryParam" : "affToken" }
};

/**
 * @return an affiliated URL for the given URL and affiliate data
 * @param url the url to operate on
 * @param affiliateData an object containing the following (optional) keys:
 *    partnerId - defines which affiliate network to use
 *    urlPrefix - the URL prefix / affiliate network through which clicks are routed for clicktracking
 *    affiliateToken - the affiliate token, that identifies an affiliate publisher to the affiliate network
 */
affiliate.affiliatedUrlForUrl = function affiliatedUrlForUrl(url, affiliateData) {
  if (!url || !affiliateData || !affiliateData['partnerId']) return url;
  var result = url;

  var partnerId = affiliateData['partnerId'];
  var urlPrefix = affiliateData['urlPrefix'];
  var affToken = affiliateData['affiliateToken'];

  var qpSep = (url.indexOf("?") > -1) ? "&" : "?";
  result += qpSep + "partnerId=" + partnerId;
	if (urlPrefix) {
    result = encodeURIComponent(result);
    if (affiliateData['partnerId'] == "30") result = encodeURIComponent(result); // LinkShare requires double encoding
    result = urlPrefix + result;
  } else if (affToken) {
    if (partnerId == "30") { // LS
			result += "&siteID=" + affToken;
		} else if (partnerId == "2003") { // TD
			result += "&tduid=" + affToken;
		} else if (partnerId == "1002") { // DGM
			result += "&affToken=" + affToken;
	 }
	}
  return result;
}

/**
 * The return object will contain these keys (all optional)
 *    partnerId
 *    urlPrefix
 *    affiliateToken
 * @return a dictionary of affiliate data based on the passed-in URL, never null.
 */
affiliate.affiliateDataFromUrl = function affiliateDataFromUrl(url) {
  var result = {};
  var qpMap = affiliate.queryParamsForUrl(url);
  var pId = qpMap['partnerId'];
  if (!pId) return result;
  result['partnerId'] = pId;
  var qpNames = affiliate._queryParamsByPartnerId[pId];
  if (!qpNames) return result; // if we don't know the queryParamName for affToken or urlPrefix, bail.

  result['urlPrefix'] = qpMap[qpNames['urlPrefixQueryParam']];
  result['affiliateToken'] = qpMap[qpNames['affiliateTokenQueryParam']];
  return result;
}

/** @return the host for a given URL. Doesn't handle many edge cases such username/password or port numbers. */
affiliate.hostForUrl = function hostForUrl(url) {
  if (!url || (url.length == 0)) return null;
  var beginIdx = url.indexOf('://' + 1);
  var endIdx = url.indexOf('/', beginIdx); // obviously ignores ports, passwords, etc
  return url.substring(beginIdx, endIdx);  
}

/** @return a dictionary of query parameters extracted from the given URL.  Values will be URI decoded. */
affiliate.queryParamsForUrl = function queryParamsForUrl(url) {
  var result = {};
  if (!url || (url.length == 0)) return result;
  var qsStart =  url.indexOf('?') + 1;
  if (qsStart == 0 || qsStart == url.length) return result; // no query string found

  var keyValues = url.slice(qsStart).split('&');
  $.each(keyValues, function(index, kvPair) {
    var keyValue = kvPair.split('=');
    result[keyValue[0]] = decodeURIComponent(keyValue[1]);
  });
  return result;
}

