/* File: ImageBrowserOptions.h

   Abstract: Header file containing project options.

   Version: 1.0

   Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
   Apple Inc. ("Apple") in consideration of your agreement to the
   following terms, and your use, installation, modification or
   redistribution of this Apple software constitutes acceptance of
   these terms.  If you do not agree with these terms, please do not
   use, install, modify or redistribute this Apple software.

   In consideration of your agreement to abide by the following terms,
   and subject to these terms, Apple grants you a personal,
   non-exclusive license, under Apple's copyrights in this original
   Apple software (the "Apple Software"), to use, reproduce, modify and
   redistribute the Apple Software, with or without modifications, in
   source and/or binary forms; provided that if you redistribute the
   Apple Software in its entirety and without modifications, you must
   retain this notice and the following text and disclaimers in all
   such redistributions of the Apple Software.  Neither the name,
   trademarks, service marks or logos of Apple Inc.  may be used to
   endorse or promote products derived from the Apple Software without
   specific prior written permission from Apple.  Except as expressly
   stated in this notice, no other rights or licenses, express or
   implied, are granted by Apple herein, including but not limited to
   any patent rights that may be infringed by your derivative works or
   by other works in which the Apple Software may be incorporated.

   The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
   MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT
   LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE
   APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH
   YOUR PRODUCTS.

   IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
   INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE
   USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE
   SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
   (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE
   HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   Copyright (C) 2010 Apple Inc. All Rights Reserved. */

/* When set to "1" ImageBrowserItemLayer defers image loading to a
   background thread instead of loading images on the main thread the
   first time they're needed. */

#define USE_IMAGE_THREAD 1

/* When set to "1", use the shadowPath property to define shadows. */

#define USE_SHADOW_PATH 1

/* When set to "1" ImageBrowserItemLayer draws each image into its
   backing store, i.e. shrinks the image to its displayed size, rather
   than setting the image directly as its contents property. In this
   mode shadows are drawn into the layer's backing store using Core
   Graphics instead of using the CALayer shadows. */

#define DOWNSAMPLE_IMAGES 1

/* When set to "1" ImageBrowserView sets the opaque property of each
   item view to YES. Only has an effect when DOWNSAMPLE_IMAGES=1. */

#define OPAQUE_ITEM_VIEWS 1

/* When set non-zero, the scroller will progressively fade out its top
   and bottom edges. When set to "1", does that setting the CALayer
   'mask' property to a view containing two gradient layers, when set
   to "2", does that by compositing two gradient layers over the
   scroller contents. */

#define SOFT_SCROLLER_EDGES 2
