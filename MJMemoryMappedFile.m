//
//  Copyright (c) 2013 Martin Johannesson
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//  (MIT License)
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "MJMemoryMappedFile.h"
#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>
#import <sys/mman.h>

@implementation MJMemoryMappedFile

- (id)initWithPath:(NSString *)pathToFile
{
    self = [super init];
	if (self) {
		_path = [pathToFile copy];
	}
	
	return self;
}

- (void)dealloc
{
	if ([self isMapped]) {
		[self unmap];
	}
}

- (void *)map
{
	if ([self isMapped]) {
		return baseAddress;
	}
	
	// This will be released when "path" is released.
	const char *cPath = [_path cStringUsingEncoding:NSUTF8StringEncoding];
	
	// The file must be opened so we can pass the file descriptor to mmap().
	int file = open(cPath, O_RDONLY);
	if (file == -1) {
		perror("open");
		return NULL;
	}
	
	// Get info about file, we need the file size.
	struct stat buffer;
	if (fstat(file, &buffer) == -1) {
		perror("fstat");
		close(file);
		return NULL;
	}
	
	// Map the file as read only pages.
	_baseAddress = mmap(NULL, buffer.st_size, PROT_READ, MAP_SHARED, file, 0);
	if (_baseAddress == MAP_FAILED) {
		perror("mmap");
		close(file);
		return NULL;
	}
    
	// Store the size, we need it when we unmap the file.
	_size = (NSUInteger)buffer.st_size;
    
	// It's ok to close() after mmap().
	if (close(file) == -1) {
		perror("close");
		[self unmap];
		return NULL;
	}
	
	return baseAddress;
}

- (void)unmap
{
	// Only unmap the file if it is actually mapped.
	if ([self isMapped]) {
		if (munmap(_baseAddress, _size) == -1) {
			// There's not much we can do if munmap() fails.
			perror("munmap");
		}
		
		_baseAddress = NULL;
		_size = 0;
	}
}

- (BOOL)isMapped
{
	return _baseAddress != NULL;
}

@end
