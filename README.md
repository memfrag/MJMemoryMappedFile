MJMemoryMappedFile
==================

An Objective-C class for mapping a file into virtual memory.

Licensed under the MIT license.

Overview
========

One of the difficult parts of writing advanced apps, such as games, is memory management. One useful “trick” is to map files into the virtual memory space, instead of actually loading the file.

When you map a file into the virtual memory space, you get a memory pointer to the start of the file and you can use that pointer as if the file had been loaded straight into memory. When you access different parts of the file those particular parts will be loaded into physical memory on demand.

When the system is running out of memory, it will throw out the parts of memory mapped files that have been loaded into the physical memory before it starts complaining about being short on memory. When the app tries to access the unloaded part of the mapped memory again, it will be loaded back into physical memory.

Obviously, accessing the mapped memory is not as fast as just accessing physical memory when you access a part of the file that is not currently in physical memory, but it’s almost like free extra memory for your app, so for code that does not need to be super fast it is sufficient (Note that this is only true for files that are mapped into memory as read-only).

On the iPhone, you can memory map files in at least two ways. One is to use the mmap() system call and the other is to use NSData with the +(id)dataWithContentsOfMappedFile: initializer method.

For the purposes of my app, I want to use Objective-C objects for memory mapping files, but as the documentation is kind of vague when it comes to describing exactly how NSData is implemented, I have chosen to implement my own class for memory mapped files that simply wraps the mmap() system call. When it comes to memory management, it’s usually a good idea to be somewhat paranoid and make sure you know exactly what is going on behind the scenes.

    MJMemoryMappedFile *file = [MJMemoryMappedFile alloc] initWithPath:path];
    
    void *pointer = [file map];
    if (pointer == NULL) {
        // The path was likely incorrect.
    }
    
    // Do whatever read-only operations you want with the pointer.
    
    [file unmap];
    
    // At this point, the pointer is not valid anymore.
