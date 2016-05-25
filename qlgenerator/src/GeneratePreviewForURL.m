//
//  GeneratePreviewForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "tools.h"
#import "bpg_decode.h"
#import "webp_decode.h"
#import "netpbm_decode.h"


// To enable logging --> defaults write -g QLEnableLogging NO
OSStatus GeneratePreviewForURL(void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);
CF_RETURNS_RETAINED static CFDictionaryRef _create_properties(CFURLRef url, const size_t size, const size_t width, const size_t height, const bool b);


OSStatus GeneratePreviewForURL(__unused void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options)
{
	@autoreleasepool
	{
		NSString* extension = [[(__bridge NSURL*)url pathExtension] lowercaseString];
		if ([extension isEqualToString:@"webp"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pbm"] || [extension isEqualToString:@"bpg"])
		{
			// Non-standard images (not supported by the OS by default)
			// Check by extension because it's highly unprobable that an UTI for these formats is declared

			// 1. decode the image
			if (!QLPreviewRequestIsCancelled(preview))
			{
				image_infos infos;
				memset(&infos, 0, sizeof(image_infos));
				CGImageRef img_ref = NULL;
				CFStringRef filepath = CFURLCopyPath(url);
				if ([extension isEqualToString:@"webp"])
					img_ref = decode_webp_at_path(filepath, &infos);
				else if ([extension isEqualToString:@"bpg"])
					img_ref = decode_bpg_at_path(filepath, &infos);
				else
					img_ref = decode_netpbm_at_path(filepath, &infos);
				if (filepath != NULL)
					CFRelease(filepath);

				// 2. render it
				CFDictionaryRef properties = _create_properties(url, infos.filesize, infos.width, infos.height, true);
				if (img_ref != NULL)
				{
					// Have to draw the image ourselves
					CGContextRef ctx = QLPreviewRequestCreateContext(preview, (CGSize){.width = infos.width, .height = infos.height}, YES, properties);
					CGContextDrawImage(ctx, (CGRect){.origin = CGPointZero, .size.width = infos.width, .size.height = infos.height}, img_ref);
					QLPreviewRequestFlushContext(preview, ctx);
					CGContextRelease(ctx);
					CGImageRelease(img_ref);
				}
				else
					QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);
				if (properties != NULL)
					CFRelease(properties);
			}
		}
		else
		{
			// Standard images (supported by the OS by default)

			size_t width = 0, height = 0, file_size = 0;
			properties_for_file(url, &width, &height, &file_size);

			// Request preview with updated titlebar
			CFDictionaryRef properties = _create_properties(url, file_size, width, height, false);
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);

			if (properties != NULL)
				CFRelease(properties);
		}
	}
	return kQLReturnNoError;
}

void CancelPreviewGeneration(__unused void* thisInterface, __unused QLPreviewRequestRef preview)
{
}

CF_RETURNS_RETAINED static CFDictionaryRef _create_properties(CFURLRef url, const size_t size, const size_t width, const size_t height, const bool b)
{
	// Format file size (algorithm inspired by Pascal Pfiffner's QuickLookCSV)
    float bytes = size;
	NSString* fmt = nil;
    char* strFormat[] = {"%.0f", "%.0f", "%.1f", "%.2f", "%.2f", "%.2f"};
    char* units[] = {"byte", "KB", "MB", "GB", "TB", "PB"};
    int i = 0;
    
    while (bytes >= 1000){ // seems like Finder uses 1000 instead of 1024
        bytes /= 1000;
        i++;
    }
    
    fmt = [[NSString alloc] initWithFormat:@"%s %s", strFormat[i], units[i]];
    fmt = [NSString stringWithFormat:fmt, bytes];

	// Get filename
	CFStringRef filename = CFURLCopyLastPathComponent(url);

	// Create props
	CFDictionaryRef properties = NULL;
	if (b)
	{
		CFTypeRef keys[3] = {kQLPreviewPropertyDisplayNameKey, kQLPreviewPropertyWidthKey, kQLPreviewPropertyHeightKey};
		// filename (widthxheight, size bytes)
		CFTypeRef values[3] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%@ (%d×%d, %@)"), filename, (int)width, (int)height, fmt), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &width), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &height)};
		properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(values[0]);
		CFRelease(values[1]);
		CFRelease(values[2]);
	}
	else
	{
		CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
		// filename (widthxheight, size bytes)
		CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%@ (%d×%d, %@)"), filename, (int)width, (int)height, fmt)};
		properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(values[0]);
	}

	CFRelease(filename);

	return properties;
}
