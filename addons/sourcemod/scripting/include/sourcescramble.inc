/**
 * Memory patching utilities.
 */

#if defined __sourcescramble_ext_included
	#endinput
#endif

#define __sourcescramble_ext_included

methodmap MemoryPatch < Handle {
	/**
	 * Loads a memory patch from a game config handle.
	 */
	public static native MemoryPatch CreateFromConf(Handle gameconf, const char[] name);
	
	/**
	 * Returns true if the contents at the memory location for the patch matches the contents
	 * specified in the game config.  If the game config does not specify any verify section,
	 * this always returns true.
	 */
	public native bool Validate();
	
	/**
	 * Enables the memory patch.  Returns false if the validation check fails or the patch has
	 * already been applied.
	 */
	public native bool Enable();
	
	/**
	 * Disables a memory patch.
	 */
	public native void Disable();
	
	/**
	 * Returns the starting address of the patch, equivalent to the address of the patch's
	 * dependent signature plus the patch offset.
	 */
	property Address Address {
		public native get();
	}
};

methodmap MemoryBlock < Handle {
	/**
	 * Allocates a fixed amount of memory, initializing the contents to zero.
	 * Size is in bytes.
	 */
	public native MemoryBlock(int size);
	
	/**
	 * Disowns the associated memory block, allowing it to remain allocated even when the handle
	 * is deleted.  Disowning the memory does not invalidate the handle.
	 * 
	 * Only use this if you are certain that something else will free (or has freed) the memory
	 * block.
	 */
	public native void Disown();
	
	/**
	 * Returns the address of the allocated memory block.
	 */
	property Address Address {
		public native get();
	}
	
	/**
	 * Returns the size of the allocated memory block.
	 */
	property int Size {
		public native get();
	}
	
	/**
	 * Load up to 4 bytes from an offset to the memory block, performing bounds checks to ensure
	 * reads are contained within the block.
	 */
	public int LoadFromOffset(int offset, NumberType size) {
		if (offset < 0 || offset + GetNumberTypeByteSize(size) > this.Size) {
			ThrowError("Cannot perform MemoryBlock access of %d bytes at offset %d (limit %d)",
					GetNumberTypeByteSize(size), offset, this.Size);
		}
		return LoadFromAddress(this.Address + view_as<Address>(offset), size);
	}
	
	/**
	 * Store up to 4 bytes to an offset to the memory block, performing bounds checks to ensure
	 * writes are contained within the block.
	 */
	public void StoreToOffset(int offset, int data, NumberType size) {
		if (offset < 0 || offset + GetNumberTypeByteSize(size) > this.Size) {
			ThrowError("Cannot perform MemoryBlock access of %d bytes at offset %d (limit %d)",
					GetNumberTypeByteSize(size), offset, this.Size);
		}
		StoreToAddress(this.Address + view_as<Address>(offset), data, size);
	}
};

static stock int GetNumberTypeByteSize(NumberType size) {
	switch (size) {
		case NumberType_Int8: return 1;
		case NumberType_Int16: return 2;
		case NumberType_Int32: return 4;
	}
	ThrowError("Unknown NumberType %d.  Did the SourceMod developers add some new ones?", size);
	return 1; // maybe `return (1 << size);` ?
}

/**
 * Returns the physical memory address of a given SourcePawn cell reference.
 */
native Address GetAddressOfCell(any& cell);

/**
 * Returns the physical memory address of a given string.
 */
native Address GetAddressOfString(char[] array);

public Extension __ext_sourcescramble = {
	name = "Source Scramble",
	file = "sourcescramble.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_sourcescramble_SetNTVOptional() {
}
#endif
