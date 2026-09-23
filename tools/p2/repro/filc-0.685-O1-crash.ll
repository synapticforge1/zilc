; ModuleID = 'BitcodeBuffer'
target datalayout = "e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target datalayout_after_filc = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-musl"

%debug.SelfInfo = type { %mem.Allocator, %"hash_map.HashMap(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)" }
%mem.Allocator = type { ptr, ptr }
%"hash_map.HashMap(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)" = type { %"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)", %mem.Allocator }
%"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)" = type { ptr, i32, i32, %debug.SafetyLock, [7 x i8] }
%debug.SafetyLock = type { i1 }
%debug.Dwarf.abi.RegisterContext = type { i1, i1 }
%"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column,null)" = type { { ptr, i64 }, i64 }
%"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange,null)" = type { { ptr, i64 }, i64 }
%debug.SelfInfo.VirtualMachine.ColumnRange = type { i64, i8, [7 x i8] }
%debug.SelfInfo.VirtualMachine.Row = type { i64, %debug.SelfInfo.VirtualMachine.Column, %debug.SelfInfo.VirtualMachine.ColumnRange, i1, [7 x i8] }
%debug.SelfInfo.VirtualMachine.Column = type { %debug.SelfInfo.VirtualMachine.RegisterRule, { i8, i8 }, [6 x i8] }
%debug.SelfInfo.VirtualMachine.RegisterRule = type { { ptr, i64 }, i4, [7 x i8] }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true })" = type { %"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value,null)" }
%"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value,null)" = type { { ptr, i64 }, i64 }
%fs.File.OpenFlags = type { i2, i2, i1, i1 }
%debug.Dwarf.ElfModule = type { i64, %debug.Dwarf, { ptr, i64 }, { ptr, i64 } }
%debug.Dwarf = type { [14 x { %debug.Dwarf.Section, i8, [7 x i8] }], %"array_list.Aligned(debug.Dwarf.Abbrev.Table,null)", %"array_list.Aligned(debug.Dwarf.CompileUnit,null)", %"array_list.Aligned(debug.Dwarf.Func,null)", { %debug.Dwarf.ExceptionFrameHeader, i8, [7 x i8] }, %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false)", %"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry,null)", %"array_list.Aligned(debug.Dwarf.Range,null)", i1, i1, [6 x i8] }
%debug.Dwarf.Section = type { { ptr, i64 }, { i64, i8, [7 x i8] }, i1, [7 x i8] }
%"array_list.Aligned(debug.Dwarf.Abbrev.Table,null)" = type { { ptr, i64 }, i64 }
%"array_list.Aligned(debug.Dwarf.CompileUnit,null)" = type { { ptr, i64 }, i64 }
%"array_list.Aligned(debug.Dwarf.Func,null)" = type { { ptr, i64 }, i64 }
%debug.Dwarf.ExceptionFrameHeader = type { i64, i64, { ptr, i64 }, i8, [7 x i8] }
%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false)" = type { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data)", ptr, %debug.SafetyLock, [7 x i8] }
%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data)" = type { ptr, i64, i64 }
%"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry,null)" = type { { ptr, i64 }, i64 }
%"array_list.Aligned(debug.Dwarf.Range,null)" = type { { ptr, i64 }, i64 }
%debug.Dwarf.CommonInformationEntry = type { i64, { ptr, i64 }, { ptr, i64 }, { i64, i8, [7 x i8] }, { ptr, i64 }, i32, i32, i8, i8, i1, { i8, i8 }, i8, i8, { i8, i8 }, i8, [6 x i8] }
%debug.Dwarf.FrameDescriptionEntry = type { i64, i64, i64, { i64, i8, [7 x i8] }, { ptr, i64 }, { ptr, i64 } }
%debug.Dwarf.EhPointerContext = type { i64, { i64, i8, [7 x i8] }, { i64, i8, [7 x i8] }, { i64, i8, [7 x i8] }, i1, [7 x i8] }
%debug.SourceLocation = type { i64, i64, { ptr, i64 } }
%debug.Dwarf.DebugRangeIterator = type { i64, ptr, ptr, %debug.FixedBufferReader, i4, [7 x i8] }
%debug.FixedBufferReader = type { { ptr, i64 }, i64, i1, [7 x i8] }
%debug.Dwarf.PcRange = type { i64, i64 }
%debug.Symbol = type { { ptr, i64 }, { ptr, i64 }, { %debug.SourceLocation, i8, [7 x i8] } }
%debug.StackIterator = type { { i64, i8, [7 x i8] }, i64, { %debug.StackIterator__struct_2002, i8, [7 x i8] }, %debug.MemoryAccessor, [4 x i8] }
%debug.StackIterator__struct_2002 = type { ptr, %debug.SelfInfo.UnwindContext, i16, i1, [5 x i8] }
%debug.SelfInfo.UnwindContext = type { %mem.Allocator, { i64, i8, [7 x i8] }, i64, ptr, %debug.SelfInfo.VirtualMachine, %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true })", %debug.Dwarf.abi.RegisterContext, [6 x i8] }
%debug.SelfInfo.VirtualMachine = type { %"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column,null)", %"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange,null)", %debug.SelfInfo.VirtualMachine.Row, { %debug.SelfInfo.VirtualMachine.Row, i8, [7 x i8] } }
%debug.MemoryAccessor = type { %fs.File }
%fs.File = type { i32 }
%"atomic.Value(u8)" = type { i8 }
%fmt.Options = type { { i64, i8, [7 x i8] }, { i64, i8, [7 x i8] }, i2, i8, [6 x i8] }
%mem.Allocator.VTable = type { ptr, ptr, ptr, ptr }
%heap.arena_allocator.ArenaAllocator = type { %mem.Allocator, %heap.arena_allocator.ArenaAllocator.State }
%heap.arena_allocator.ArenaAllocator.State = type { %SinglyLinkedList, i64 }
%SinglyLinkedList = type { ptr }
%builtin.Type.Int = type { i16, i1, [1 x i8] }
%"array_list.Aligned(u8,null)" = type { { ptr, i64 }, i64 }
%fs.Dir.OpenOptions = type { i1, i1, i1 }
%Io.Writer.VTable = type { ptr, ptr, ptr, ptr }
%"array_list.Aligned(debug.Dwarf.FileEntry,null)" = type { { ptr, i64 }, i64 }
%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false)" = type { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data)", ptr, %debug.SafetyLock, [7 x i8] }
%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data)" = type { ptr, i64, i64 }
%Thread.Mutex.Recursive = type { i64, %Thread.Mutex, i32, [4 x i8] }
%Thread.Mutex = type { %Thread.Mutex.DebugImpl }
%Thread.Mutex.DebugImpl = type { %"atomic.Value(u32)", %Thread.Mutex.FutexImpl }
%"atomic.Value(u32)" = type { i32 }
%Thread.Mutex.FutexImpl = type { %"atomic.Value(u32)" }
%fs.File.Writer = type { i64, %Io.Writer, %fs.File, i16, i16, i16, i16, i16, i3, [1 x i8] }
%Io.Writer = type { ptr, { ptr, i64 }, i64 }
%debug.Dwarf.call_frame.Instruction = type { %debug.Dwarf.call_frame.Instruction__struct_7801, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7801 = type { { ptr, i64 }, i8, [7 x i8] }
%debug.StackIterator.getLastError__struct_5143 = type { i64, i16, [6 x i8] }
%dynamic_library.LinkMap.Iterator = type { ptr }
%fs.File.Stat = type { i128, i128, i128, i64, i64, i64, i4, [7 x i8] }
%Io.Reader.VTable = type { ptr, ptr, ptr, ptr }
%Progress = type { { %Thread, i8, [7 x i8] }, i64, i64, { ptr, i64 }, { ptr, i64 }, { ptr, i64 }, { ptr, i64 }, %fs.File, %Thread.ResetEvent, i32, i32, i16, i16, i2, i1, i1, i2 }
%Thread = type { %Thread.LinuxThreadImpl }
%Thread.LinuxThreadImpl = type { ptr }
%Thread.ResetEvent = type { %Thread.ResetEvent.FutexImpl }
%Thread.ResetEvent.FutexImpl = type { %"atomic.Value(u32)" }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value" = type { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value__struct_2116", i2, [7 x i8] }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value__struct_2116" = type { i64, { ptr, i64 } }
%elf.Elf64_Dyn = type { i64, i64 }
%"hash.crc.impl.Crc(u32,.{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 })" = type { i32 }
%compress.flate.Container.Metadata__struct_6008 = type { i32, i32 }
%compress.flate.Container.Metadata__struct_6009 = type { i32 }
%debug.Dwarf.CompileUnit.SrcLocCache = type { %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false)", { ptr, i64 }, { ptr, i64 }, i16, [6 x i8] }
%SinglyLinkedList.Node = type { ptr }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand" = type { <{ %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand__struct_14990", [8 x i8] }>, i4, [7 x i8] }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand__struct_14990" = type { i64, i8, [7 x i8] }
%debug.Dwarf.Die = type { i64, { ptr, i64 }, i1, [7 x i8] }
%hash.wyhash.Wyhash = type { i64, i64, [3 x i64], i64, i64, [48 x i8] }
%Target.Os = type { %Target.Os.VersionRange, i6, [7 x i8] }
%Target.Os.VersionRange = type { %Target.Os.LinuxVersionRange, i3, [7 x i8] }
%Target.Os.LinuxVersionRange = type { %SemanticVersion.Range, %SemanticVersion, i32, [4 x i8] }
%SemanticVersion.Range = type { %SemanticVersion, %SemanticVersion }
%SemanticVersion = type { i64, i64, i64, { ptr, i64 }, { ptr, i64 } }
%std.Options = type { { i64, i8, [7 x i8] }, { i64, i8, [7 x i8] }, i64, i1, i2, i1, i1, i1, i1, i1, i2 }
%Target.Cpu.Feature.Set = type { [5 x i64] }
%Target.Cpu = type { ptr, %Target.Cpu.Feature.Set, i6, [7 x i8] }
%Target.Cpu.Model = type { { ptr, i64 }, { ptr, i64 }, %Target.Cpu.Feature.Set }
%Target.DynamicLinker = type { [255 x i8], i8 }
%Target = type { %Target.Cpu, %Target.Os, i5, i4, %Target.DynamicLinker, [6 x i8] }
%builtin.CallingConvention.CommonOptions = type { { i64, i8, [7 x i8] } }
%compress.flate.Token.MatchLength = type { i16, i16, i8, i8, i4, [1 x i8] }
%compress.flate.Token.MatchDistance = type { i16, i16, i16, i8, i4 }
%os.linux.rusage = type { %os.linux.x86_64.timeval, %os.linux.x86_64.timeval, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, [16 x i64] }
%os.linux.x86_64.timeval = type { i64, i64 }
%"array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true)" = type { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true).Data)", ptr, %debug.SafetyLock, [7 x i8] }
%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true).Data)" = type { ptr, i64, i64 }
%"array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true)" = type { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true).Data)", ptr, %debug.SafetyLock, [7 x i8] }
%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true).Data)" = type { ptr, i64, i64 }
%"hash_map.HashMapUnmanaged(Build.InitializedDepKey,*Build.Dependency,Build.InitializedDepContext,80)" = type { ptr, i32, i32, %debug.SafetyLock, [7 x i8] }
%"crypto.siphash.SipHash(u128,1,3)" = type { %"crypto.siphash.SipHashStateless(u128,1,3)", i64, [8 x i8] }
%"crypto.siphash.SipHashStateless(u128,1,3)" = type { i64, i64, i64, i64, i8, [7 x i8] }
%Progress.Node = type { i8 }
%Progress.Node.Storage = type { i32, i32, [40 x i8] }
%builtin.StackTrace = type { i64, { ptr, i64 } }
%os.linux.x86_64.ucontext_t = type { i64, ptr, %os.linux.stack_t__struct_1920, %os.linux.x86_64.mcontext_t, [16 x i64], [64 x i64] }
%os.linux.stack_t__struct_1920 = type { ptr, i32, [4 x i8], i64 }
%os.linux.x86_64.mcontext_t = type { [23 x i64], ptr, [8 x i64] }
%os.linux.x86_64.fpstate = type { i16, i16, i16, i16, i64, i64, i32, i32, [8 x %os.linux.x86_64.fpstate__struct_1937], [16 x %os.linux.x86_64.fpstate__struct_1939], [24 x i32] }
%os.linux.x86_64.fpstate__struct_1937 = type { [4 x i16], i16, [3 x i16] }
%os.linux.x86_64.fpstate__struct_1939 = type { [4 x i32] }
%elf.Elf64_Phdr = type { i32, i32, i64, i64, i64, i64, i64, i64 }
%debug.SelfInfo.lookupModuleDl__struct_2627 = type { i64, i64, { ptr, i64 }, { ptr, i64 }, { ptr, i64 } }
%os.linux.dl_phdr_info = type { i64, ptr, ptr, i16, [6 x i8] }
%fs.Dir = type { i32 }
%Build.Cache.Directory = type { { ptr, i64 }, %fs.Dir, [4 x i8] }
%Build.Cache.Path = type { %Build.Cache.Directory, { ptr, i64 } }
%compress.flate.Decompress = type { ptr, i64, %Io.Reader, %"compress.flate.Decompress.HuffmanDecoder(286,15,9)", %"compress.flate.Decompress.HuffmanDecoder(30,15,9)", %compress.flate.Container.Metadata, %compress.flate.Decompress.State, i16, i6, i1, [4 x i8] }
%Io.Reader = type { ptr, { ptr, i64 }, i64, i64 }
%"compress.flate.Decompress.HuffmanDecoder(286,15,9)" = type { [286 x i46], [512 x i46] }
%"compress.flate.Decompress.HuffmanDecoder(30,15,9)" = type { [30 x i46], [512 x i46] }
%compress.flate.Container.Metadata = type { <{ %compress.flate.Container.Metadata__struct_6009, [4 x i8] }>, i2, [3 x i8] }
%compress.flate.Decompress.State = type { i16, i4, [1 x i8] }
%elf.Elf64_Chdr = type { i32, i32, i64, i64 }
%elf.Elf64_Ehdr = type { [16 x i8], i16, i16, i32, i64, i64, i64, i32, i16, i16, i16, i16, i16, i16 }
%elf.Elf64_Shdr = type { i32, i32, i64, i64, i64, i64, i32, i32, i64, i64 }
%debug.Dwarf.readEhPointer__union_3046 = type { i64, i1, [7 x i8] }
%debug.Dwarf.EntryHeader = type { i64, %debug.Dwarf.EntryHeader__union_3155, { ptr, i64 }, i1, [7 x i8] }
%debug.Dwarf.EntryHeader__union_3155 = type { i64, i2, [7 x i8] }
%debug.Dwarf.UnitHeader = type { i64, i1, i4, [6 x i8] }
%dynamic_library.LinkMap = type { i64, ptr, ptr, ptr, ptr }
%debug.Dwarf.FormValue = type { <{ i64, [8 x i8] }>, i5, [7 x i8] }
%debug.Dwarf.CompileUnit = type { %debug.Dwarf.Die, { %debug.Dwarf.PcRange, i8, [7 x i8] }, i64, i64, i64, i64, ptr, { %debug.Dwarf.CompileUnit.SrcLocCache, i8, [7 x i8] }, i16, i1, [5 x i8] }
%debug.Dwarf.Die.Attr = type { i64, %debug.Dwarf.FormValue }
%debug.Dwarf.CompileUnit.SrcLocCache.LineEntry = type { i32, i32, i32 }
%debug.Dwarf.FileEntry = type { { ptr, i64 }, i64, i64, i32, [16 x i8], [4 x i8] }
%debug.Dwarf.Func = type { { %debug.Dwarf.PcRange, i8, [7 x i8] }, { ptr, i64 } }
%os.linux.Sigaction = type { %os.linux.Sigaction__union_3762, [1 x i64], i64 }
%os.linux.Sigaction__union_3762 = type { ptr }
%dynamic_library.RDebug = type { i32, [4 x i8], ptr, i64, i64 }
%os.linux.Statx = type { i32, i32, i64, i32, i32, i32, i16, i16, i64, i64, i64, i64, %os.linux.statx_timestamp, %os.linux.statx_timestamp, %os.linux.statx_timestamp, %os.linux.statx_timestamp, i32, i32, i32, i32, [14 x i64] }
%os.linux.statx_timestamp = type { i64, i32, i32 }
%Io.Writer.Allocating = type { %mem.Allocator, %Io.Writer }
%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult" = type { ptr, ptr, i64, i1, [7 x i8] }
%sort.pdq.pdq__anon_6410.Context = type { { ptr, i64 } }
%debug.SelfInfo.lookupModuleNameDl__struct_10243 = type { i64, { ptr, i64 } }
%Io.Writer.Discarding = type { i64, %Io.Writer }
%debug.Dwarf.LineNumberProgram = type { i64, i64, i64, i64, i16, i1, i1, i1, [3 x i8] }
%debug.Dwarf.runLineNumberProgram__struct_7020 = type { { ptr, i64 } }
%debug.Dwarf.runLineNumberProgram.FileEntFmt = type { i16, i16 }
%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).Slice" = type { [3 x ptr], i64, i64 }
%os.linux.k_sigaction__struct_10718 = type { ptr, i64, ptr, [1 x i64] }
%os.linux.sigset_bit_index__struct_10745 = type { i64, i64 }
%heap.arena_allocator.ArenaAllocator.BufNode = type { i64, %SinglyLinkedList.Node }
%Io.DeprecatedReader = type { ptr, ptr }
%"Io.GenericReader(*Io.fixed_buffer_stream.FixedBufferStream([]const u8),error{},(function 'read'))" = type { ptr }
%"Io.fixed_buffer_stream.FixedBufferStream([]const u8)" = type { { ptr, i64 }, i64 }
%debug.Dwarf.call_frame.Instruction__struct_7779 = type { i8 }
%debug.Dwarf.call_frame.Instruction__struct_7780 = type { i64, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7781 = type { i8 }
%debug.Dwarf.call_frame.Instruction__struct_7782 = type { i64 }
%debug.Dwarf.call_frame.Instruction__struct_7783 = type { i8 }
%debug.Dwarf.call_frame.Instruction__struct_7784 = type { i16 }
%debug.Dwarf.call_frame.Instruction__struct_7785 = type { i32 }
%debug.Dwarf.call_frame.Instruction__struct_7786 = type { i64, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7787 = type { i8 }
%debug.Dwarf.call_frame.Instruction__struct_7788 = type { i8 }
%debug.Dwarf.call_frame.Instruction__struct_7789 = type { i8 }
%debug.Dwarf.call_frame.Instruction__struct_7790 = type { i8, i8 }
%debug.Dwarf.call_frame.Instruction__struct_7791 = type { i64, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7792 = type { i8 }
%debug.Dwarf.call_frame.Instruction__struct_7793 = type { i64 }
%debug.Dwarf.call_frame.Instruction__struct_7794 = type { { ptr, i64 } }
%debug.Dwarf.call_frame.Instruction__struct_7795 = type { { ptr, i64 }, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7796 = type { i64, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7797 = type { i64, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7798 = type { i64 }
%debug.Dwarf.call_frame.Instruction__struct_7799 = type { i64, i8, [7 x i8] }
%debug.Dwarf.call_frame.Instruction__struct_7800 = type { i64, i8, [7 x i8] }
%debug.Dwarf.expression.Context = type { ptr, ptr, ptr, { ptr, i64 }, ptr, { i64, i8, [7 x i8] }, i1, { %debug.Dwarf.abi.RegisterContext, i8 }, i1, [3 x i8] }
%debug.SelfInfo.unwindFrameDwarf.RegisterUpdate = type { { ptr, i64 }, { ptr, i64 }, ptr }
%debug.Dwarf.Abbrev = type { i64, i64, { ptr, i64 }, i1, [7 x i8] }
%debug.Dwarf.Abbrev.Table = type { i64, { ptr, i64 } }
%"array_list.AlignedManaged(debug.Dwarf.Die.Attr,null)" = type { { ptr, i64 }, i64, %mem.Allocator }
%sort.pdq.pdqContext__anon_10225.Range = type { i64, i64, i64 }
%fs.File.Reader = type { i64, { i64, i8, [7 x i8] }, %Io.Reader, %fs.File, i16, i16, i16, i3, [5 x i8] }
%array_hash_map.IndexHeader = type { i8, [3 x i8] }
%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult" = type { ptr, ptr, i64, i1, [7 x i8] }
%os.linux.timespec__struct_14786 = type { i64, i64 }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand__struct_14986" = type { i64, i8, [7 x i8] }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value__struct_2115" = type { i64, i64, i8, [7 x i8] }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand__struct_14988" = type { i64, i8, [7 x i8] }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand__struct_14989" = type { i64, { ptr, i64 } }
%posix.iovec_const = type { ptr, i64 }
%posix.iovec = type { ptr, i64 }
%"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80).Header" = type { ptr, ptr, i32, [4 x i8] }
%debug.Dwarf.Abbrev.Attr = type { i64, i64, i64 }
%"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr,null)" = type { { ptr, i64 }, i64, %mem.Allocator }
%"array_list.AlignedManaged(debug.Dwarf.Abbrev,null)" = type { { ptr, i64 }, i64, %mem.Allocator }
%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).Slice" = type { [3 x ptr], i64, i64 }
%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).sortInternal__anon_14622__struct_16215" = type { %debug.Dwarf.runLineNumberProgram__struct_7020, %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).Slice" }
%"array_hash_map.Index(u8)" = type { i8, i8 }
%"array_hash_map.Index(u16)" = type { i16, i16 }
%"array_hash_map.Index(u32)" = type { i32, i32 }
%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand__struct_14987" = type { i64, i64 }
%posix.winsize = type { i16, i16, i16, i16 }
%"compress.flate.Decompress.HuffmanDecoder(19,7,7)" = type { [19 x i46], [128 x i46] }
%compress.flate.Decompress.streamInner.Header = type <{ i16, i8, i8, i32, i8, i8 }>
%sort.heap__anon_18649.Context = type { { ptr, i64 } }

@__anon_594 = internal unnamed_addr constant [17 x i8] c"integer overflow\00", align 1
@debug.self_debug_info = internal unnamed_addr global { %debug.SelfInfo, i8, [7 x i8] } { %debug.SelfInfo undef, i8 0, [7 x i8] undef }, align 8
@0 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 30, [6 x i8] undef }, align 8
@1 = private unnamed_addr constant { %debug.Dwarf.abi.RegisterContext, i8 } { %debug.Dwarf.abi.RegisterContext undef, i8 0 }, align 1
@2 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@3 = private unnamed_addr constant { %"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column,null)", %"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange,null)", { i64, { { [16 x i8], i4, [7 x i8] }, { i8, i8 }, [6 x i8] }, %debug.SelfInfo.VirtualMachine.ColumnRange, i1, [7 x i8] }, { %debug.SelfInfo.VirtualMachine.Row, i8, [7 x i8] } } { %"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, %"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, { i64, { { [16 x i8], i4, [7 x i8] }, { i8, i8 }, [6 x i8] }, %debug.SelfInfo.VirtualMachine.ColumnRange, i1, [7 x i8] } { i64 0, { { [16 x i8], i4, [7 x i8] }, { i8, i8 }, [6 x i8] } { { [16 x i8], i4, [7 x i8] } { [16 x i8] undef, i4 0, [7 x i8] undef }, { i8, i8 } { i8 undef, i8 0 }, [6 x i8] undef }, %debug.SelfInfo.VirtualMachine.ColumnRange { i64 undef, i8 0, [7 x i8] undef }, i1 false, [7 x i8] undef }, { %debug.SelfInfo.VirtualMachine.Row, i8, [7 x i8] } { %debug.SelfInfo.VirtualMachine.Row undef, i8 0, [7 x i8] undef } }, align 8
@4 = private unnamed_addr constant %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true })" { %"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 } }, align 8
@5 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__anon_2734 = internal unnamed_addr constant [1 x i8] zeroinitializer, align 1
@__anon_2767 = internal unnamed_addr constant [5 x i8] c"GNU\00\00", align 1
@6 = private unnamed_addr constant %fs.File.OpenFlags zeroinitializer, align 1
@7 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 23, [6 x i8] undef }, align 8
@8 = private unnamed_addr constant { { i64, i8, [7 x i8] }, i16, [6 x i8] } { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i16 0, [6 x i8] undef }, align 8
@9 = private unnamed_addr constant { { i64, i8, [7 x i8] }, i16, [6 x i8] } { { i64, i8, [7 x i8] } undef, i16 69, [6 x i8] undef }, align 8
@10 = private unnamed_addr constant { { i64, i8, [7 x i8] }, i16, [6 x i8] } { { i64, i8, [7 x i8] } undef, i16 70, [6 x i8] undef }, align 8
@11 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@12 = private unnamed_addr constant { { i64, i8, [7 x i8] }, i16, [6 x i8] } { { i64, i8, [7 x i8] } undef, i16 71, [6 x i8] undef }, align 8
@13 = private unnamed_addr constant { { i64, i8, [7 x i8] }, i16, [6 x i8] } { { i64, i8, [7 x i8] } undef, i16 72, [6 x i8] undef }, align 8
@14 = private unnamed_addr constant { { i64, i8, [7 x i8] }, i16, [6 x i8] } { { i64, i8, [7 x i8] } undef, i16 73, [6 x i8] undef }, align 8
@15 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 0, i8 4, [1 x i8] undef }, align 2
@16 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 0, i8 8, [1 x i8] undef }, align 2
@17 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 0, i8 16, [1 x i8] undef }, align 2
@18 = private unnamed_addr constant { [8 x i8], i2, [7 x i8] } { [8 x i8] undef, i2 -2, [7 x i8] undef }, align 8
@19 = private unnamed_addr constant { [8 x i8], i2, [7 x i8] } { [8 x i8] undef, i2 0, [7 x i8] undef }, align 8
@20 = private unnamed_addr constant { %debug.Dwarf.CommonInformationEntry, i16, [6 x i8] } { %debug.Dwarf.CommonInformationEntry undef, i16 73, [6 x i8] undef }, align 8
@21 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@22 = private unnamed_addr constant { %debug.Dwarf.CommonInformationEntry, i16, [6 x i8] } { %debug.Dwarf.CommonInformationEntry undef, i16 74, [6 x i8] undef }, align 8
@23 = private unnamed_addr constant { %debug.Dwarf.CommonInformationEntry, i16, [6 x i8] } { %debug.Dwarf.CommonInformationEntry undef, i16 75, [6 x i8] undef }, align 8
@24 = private unnamed_addr constant { i8, i8 } { i8 undef, i8 0 }, align 1
@25 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@26 = private unnamed_addr constant { %debug.Dwarf.FrameDescriptionEntry, i16, [6 x i8] } { %debug.Dwarf.FrameDescriptionEntry undef, i16 69, [6 x i8] undef }, align 8
@27 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@28 = private unnamed_addr constant %debug.Dwarf.EhPointerContext { i64 0, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i1 false, [7 x i8] undef }, align 8
@29 = private unnamed_addr constant [2 x i4] [i4 -4, i4 -5], align 1
@30 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@31 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@32 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 23, [6 x i8] undef }, align 8
@33 = private unnamed_addr constant [14 x { %debug.Dwarf.Section, i8, [7 x i8] }] [{ %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }], align 8
@34 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@35 = private unnamed_addr constant { i32, i8, [3 x i8] } { i32 undef, i8 0, [3 x i8] undef }, align 4
@36 = private unnamed_addr constant %fs.File.OpenFlags zeroinitializer, align 1
@__anon_3372 = internal unnamed_addr constant [8 x i8] c"???:?:?\00", align 1
@__anon_3379 = internal unnamed_addr constant [3 x i8] c": \00", align 1
@__anon_3396 = internal unnamed_addr constant [2 x i8] c"\0A\00", align 1
@__anon_3462 = internal unnamed_addr constant [2 x i8] c"^\00", align 1
@__anon_3328 = internal unnamed_addr constant [4 x i8] c"???\00", align 1
@37 = private unnamed_addr constant { %debug.SourceLocation, i8, [7 x i8] } { %debug.SourceLocation undef, i8 0, [7 x i8] undef }, align 8
@38 = private unnamed_addr constant { %debug.Dwarf.DebugRangeIterator, i16, [6 x i8] } { %debug.Dwarf.DebugRangeIterator undef, i16 23, [6 x i8] undef }, align 8
@39 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@40 = private unnamed_addr constant { { %debug.Dwarf.PcRange, i8, [7 x i8] }, i16, [6 x i8] } { { %debug.Dwarf.PcRange, i8, [7 x i8] } { %debug.Dwarf.PcRange undef, i8 0, [7 x i8] undef }, i16 0, [6 x i8] undef }, align 8
@__anon_2993 = internal unnamed_addr constant [1 x i8] zeroinitializer, align 1
@41 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i16 0, [6 x i8] undef }, align 8
@42 = private unnamed_addr constant { %debug.SourceLocation, i8, [7 x i8] } { %debug.SourceLocation undef, i8 0, [7 x i8] undef }, align 8
@43 = private unnamed_addr constant { %debug.Symbol, i16, [6 x i8] } { %debug.Symbol { { ptr, i64 } { ptr @__anon_3328, i64 3 }, { ptr, i64 } { ptr @__anon_3328, i64 3 }, { %debug.SourceLocation, i8, [7 x i8] } { %debug.SourceLocation undef, i8 0, [7 x i8] undef } }, i16 0, [6 x i8] undef }, align 8
@44 = private unnamed_addr constant { %debug.StackIterator, i8, [7 x i8] } { %debug.StackIterator undef, i8 0, [7 x i8] undef }, align 8
@45 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__zig_err_name_table = private unnamed_addr constant ptr @804, align 8
@debug.panic_stage = internal thread_local unnamed_addr global i64 0, align 8
@debug.panicking = internal unnamed_addr global %"atomic.Value(u8)" zeroinitializer, align 1
@__anon_3755 = internal unnamed_addr constant [33 x i8] c"aborting due to recursive panic\0A\00", align 1
@46 = private unnamed_addr constant { ptr } zeroinitializer, align 8
@__anon_3949 = internal unnamed_addr constant [7 x i8] c"thread ", align 1
@47 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@48 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_4099 = internal unnamed_addr constant [8 x i8] c" panic: ", align 1
@posix.abort.global.abort_entered = internal unnamed_addr global i1 false, align 1
@49 = private unnamed_addr constant { ptr } zeroinitializer, align 8
@50 = private unnamed_addr constant [1 x i8] c"s", align 1
@__anon_4173 = internal unnamed_addr constant [1 x i8] c"s", align 1
@51 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@52 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_4213 = internal unnamed_addr constant [1 x i8] c"\0A", align 1
@53 = private unnamed_addr constant %"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)" { ptr null, i32 0, i32 0, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@debug.debug_info_allocator = internal unnamed_addr global { %mem.Allocator, i8, [7 x i8] } { %mem.Allocator undef, i8 0, [7 x i8] undef }, align 8
@heap.PageAllocator.vtable = internal unnamed_addr constant %mem.Allocator.VTable { ptr @heap.PageAllocator.alloc, ptr @heap.PageAllocator.resize, ptr @heap.PageAllocator.remap, ptr @heap.PageAllocator.free }, align 8
@54 = private unnamed_addr constant %mem.Allocator { ptr undef, ptr @heap.PageAllocator.vtable }, align 8
@debug.debug_info_arena_allocator = internal unnamed_addr global %heap.arena_allocator.ArenaAllocator undef, align 8
@__anon_4296 = internal unnamed_addr constant [26 x i8] c"attempt to use null value\00", align 1
@__anon_4404 = internal unnamed_addr constant [55 x i8] c"Unable to dump stack trace: Unable to open debug info: ", align 1
@55 = private unnamed_addr constant [1 x i8] c"s", align 1
@56 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@57 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@58 = private unnamed_addr constant %debug.MemoryAccessor { %fs.File { i32 -1 } }, align 4
@59 = private unnamed_addr constant { %debug.StackIterator__struct_2002, i8, [7 x i8] } { %debug.StackIterator__struct_2002 undef, i8 0, [7 x i8] undef }, align 8
@60 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 25, [6 x i8] undef }, align 8
@61 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__anon_5186 = internal unnamed_addr constant [31 x i8] c"cast causes pointer to be null\00", align 1
@62 = private unnamed_addr constant %builtin.Type.Int { i16 8, i1 true, [1 x i8] undef }, align 2
@__anon_5480 = internal unnamed_addr constant [5 x i8] c"\7FELF\00", align 1
@__anon_5516 = internal unnamed_addr constant [15 x i8] c"/proc/self/exe\00", align 1
@__anon_5530 = internal unnamed_addr constant [24 x i8] c"switch on corrupt value\00", align 1
@63 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 16, [6 x i8] undef }, align 8
@64 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 20, [6 x i8] undef }, align 8
@65 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 60, [6 x i8] undef }, align 8
@66 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 59, [6 x i8] undef }, align 8
@67 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 46, [6 x i8] undef }, align 8
@68 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 47, [6 x i8] undef }, align 8
@69 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 31, [6 x i8] undef }, align 8
@70 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 61, [6 x i8] undef }, align 8
@71 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 32, [6 x i8] undef }, align 8
@72 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 62, [6 x i8] undef }, align 8
@73 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 63, [6 x i8] undef }, align 8
@74 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 64, [6 x i8] undef }, align 8
@75 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 65, [6 x i8] undef }, align 8
@76 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 66, [6 x i8] undef }, align 8
@77 = private unnamed_addr constant [14 x { %debug.Dwarf.Section, i8, [7 x i8] }] [{ %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }], align 8
@78 = private unnamed_addr constant { i32, i8, [3 x i8] } { i32 undef, i8 0, [3 x i8] undef }, align 4
@__anon_5770 = internal unnamed_addr constant [15 x i8] c".gnu_debuglink\00", align 1
@79 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__anon_5787 = internal unnamed_addr constant [12 x i8] c".debug_info\00", align 1
@80 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 0, i8 1, [7 x i8] undef }, align 8
@__anon_5796 = internal unnamed_addr constant [14 x i8] c".debug_abbrev\00", align 1
@81 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 1, i8 1, [7 x i8] undef }, align 8
@__anon_5806 = internal unnamed_addr constant [11 x i8] c".debug_str\00", align 1
@82 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 2, i8 1, [7 x i8] undef }, align 8
@__anon_5815 = internal unnamed_addr constant [19 x i8] c".debug_str_offsets\00", align 1
@83 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 3, i8 1, [7 x i8] undef }, align 8
@__anon_5822 = internal unnamed_addr constant [12 x i8] c".debug_line\00", align 1
@84 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 4, i8 1, [7 x i8] undef }, align 8
@__anon_5832 = internal unnamed_addr constant [16 x i8] c".debug_line_str\00", align 1
@85 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 5, i8 1, [7 x i8] undef }, align 8
@__anon_5840 = internal unnamed_addr constant [14 x i8] c".debug_ranges\00", align 1
@86 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 6, i8 1, [7 x i8] undef }, align 8
@__anon_5847 = internal unnamed_addr constant [16 x i8] c".debug_loclists\00", align 1
@87 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 7, i8 1, [7 x i8] undef }, align 8
@__anon_5854 = internal unnamed_addr constant [16 x i8] c".debug_rnglists\00", align 1
@88 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 8, i8 1, [7 x i8] undef }, align 8
@__anon_5861 = internal unnamed_addr constant [12 x i8] c".debug_addr\00", align 1
@89 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 9, i8 1, [7 x i8] undef }, align 8
@__anon_5868 = internal unnamed_addr constant [13 x i8] c".debug_names\00", align 1
@90 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 10, i8 1, [7 x i8] undef }, align 8
@__anon_5876 = internal unnamed_addr constant [13 x i8] c".debug_frame\00", align 1
@91 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 11, i8 1, [7 x i8] undef }, align 8
@__anon_5883 = internal unnamed_addr constant [10 x i8] c".eh_frame\00", align 1
@92 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 12, i8 1, [7 x i8] undef }, align 8
@__anon_5891 = internal unnamed_addr constant [14 x i8] c".eh_frame_hdr\00", align 1
@93 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 13, i8 1, [7 x i8] undef }, align 8
@94 = private unnamed_addr constant %"array_list.Aligned(u8,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@95 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 23, [6 x i8] undef }, align 8
@__anon_6066 = internal unnamed_addr constant [22 x i8] c"DEBUGINFOD_CACHE_PATH\00", align 1
@96 = private unnamed_addr constant %fs.Dir.OpenOptions { i1 true, i1 false, i1 false }, align 1
@__anon_6079 = internal unnamed_addr constant [15 x i8] c"XDG_CACHE_HOME\00", align 1
@__anon_6083 = internal unnamed_addr constant [18 x i8] c"debuginfod_client\00", align 1
@__anon_6089 = internal unnamed_addr constant [5 x i8] c"HOME\00", align 1
@__anon_6094 = internal unnamed_addr constant [7 x i8] c".cache\00", align 1
@__anon_6136 = internal unnamed_addr constant [15 x i8] c"/usr/lib/debug\00", align 1
@97 = private unnamed_addr constant [1 x { ptr, i64 }] [{ ptr, i64 } { ptr @__anon_6136, i64 14 }], align 8
@__anon_6141 = internal unnamed_addr constant [7 x i8] c".debug\00", align 1
@__anon_6174 = internal unnamed_addr constant [10 x i8] c".build-id\00", align 1
@__anon_5783 = internal unnamed_addr constant [2 x i8] c".\00", align 1
@98 = private unnamed_addr constant %"array_list.Aligned(debug.Dwarf.Abbrev.Table,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@99 = private unnamed_addr constant %"array_list.Aligned(debug.Dwarf.CompileUnit,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@100 = private unnamed_addr constant %"array_list.Aligned(debug.Dwarf.Func,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@101 = private unnamed_addr constant { %debug.Dwarf.ExceptionFrameHeader, i8, [7 x i8] } { %debug.Dwarf.ExceptionFrameHeader undef, i8 0, [7 x i8] undef }, align 8
@102 = private unnamed_addr constant %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false)" { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data)" { ptr undef, i64 0, i64 0 }, ptr null, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@103 = private unnamed_addr constant %"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@104 = private unnamed_addr constant %"array_list.Aligned(debug.Dwarf.Range,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@105 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 67 }, align 2
@106 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 67, [2 x i8] undef }, align 4
@107 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 67, [6 x i8] undef }, align 8
@108 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@109 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@110 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@111 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@112 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 67 }, align 2
@113 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 67, [2 x i8] undef }, align 4
@114 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 67, [6 x i8] undef }, align 8
@__anon_6282 = internal unnamed_addr constant [41 x i8] c"integer does not fit in destination type\00", align 1
@115 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@__anon_6290 = internal unnamed_addr constant [20 x i8] c"incorrect alignment\00", align 1
@__anon_6322 = internal unnamed_addr constant [25 x i8] c"reached unreachable code\00", align 1
@116 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@117 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@118 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@119 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 66, [2 x i8] undef }, align 4
@120 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@121 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 66, [2 x i8] undef }, align 4
@122 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@123 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 66, i8 undef, [1 x i8] undef }, align 2
@124 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@125 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@126 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@127 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@__anon_6467 = internal unnamed_addr constant [6 x i8] c"\1B[30m\00", align 1
@__anon_6469 = internal unnamed_addr constant [6 x i8] c"\1B[31m\00", align 1
@__anon_6471 = internal unnamed_addr constant [6 x i8] c"\1B[32m\00", align 1
@__anon_6473 = internal unnamed_addr constant [6 x i8] c"\1B[33m\00", align 1
@__anon_6475 = internal unnamed_addr constant [6 x i8] c"\1B[34m\00", align 1
@__anon_6477 = internal unnamed_addr constant [6 x i8] c"\1B[35m\00", align 1
@__anon_6479 = internal unnamed_addr constant [6 x i8] c"\1B[36m\00", align 1
@__anon_6481 = internal unnamed_addr constant [6 x i8] c"\1B[37m\00", align 1
@__anon_6483 = internal unnamed_addr constant [6 x i8] c"\1B[90m\00", align 1
@__anon_6485 = internal unnamed_addr constant [6 x i8] c"\1B[91m\00", align 1
@__anon_6487 = internal unnamed_addr constant [6 x i8] c"\1B[92m\00", align 1
@__anon_6489 = internal unnamed_addr constant [6 x i8] c"\1B[93m\00", align 1
@__anon_6491 = internal unnamed_addr constant [6 x i8] c"\1B[94m\00", align 1
@__anon_6493 = internal unnamed_addr constant [6 x i8] c"\1B[95m\00", align 1
@__anon_6495 = internal unnamed_addr constant [6 x i8] c"\1B[96m\00", align 1
@__anon_6497 = internal unnamed_addr constant [6 x i8] c"\1B[97m\00", align 1
@__anon_6499 = internal unnamed_addr constant [5 x i8] c"\1B[1m\00", align 1
@__anon_6501 = internal unnamed_addr constant [5 x i8] c"\1B[2m\00", align 1
@__anon_6503 = internal unnamed_addr constant [5 x i8] c"\1B[0m\00", align 1
@128 = private unnamed_addr constant [1 x i8] c"s", align 1
@129 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@130 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_6573 = internal unnamed_addr constant [1 x i8] c":", align 1
@131 = private unnamed_addr constant [1 x i8] c"d", align 1
@__anon_6580 = internal unnamed_addr constant [1 x i8] c"d", align 1
@132 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6580, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@__anon_6664 = internal unnamed_addr constant [2 x i8] c"0x", align 1
@133 = private unnamed_addr constant [1 x i8] c"x", align 1
@__anon_6671 = internal unnamed_addr constant [1 x i8] c"x", align 1
@134 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6671, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@135 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_6692 = internal unnamed_addr constant [4 x i8] c" in ", align 1
@136 = private unnamed_addr constant [1 x i8] c"s", align 1
@137 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@__anon_6708 = internal unnamed_addr constant [2 x i8] c" (", align 1
@__anon_6720 = internal unnamed_addr constant [1 x i8] c")", align 1
@138 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 4, [6 x i8] undef }, align 8
@__anon_6739 = internal unnamed_addr constant [1 x { ptr, i64 }] [{ ptr, i64 } { ptr @__anon_2734, i64 0 }], align 8
@139 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@140 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@__anon_6762 = internal unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.fixedDrain, ptr @Io.Writer.unimplementedSendFile, ptr @Io.Writer.defaultFlush, ptr @Io.Writer.defaultRebase }, align 8
@141 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@142 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 23, [6 x i8] undef }, align 8
@143 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 67, [6 x i8] undef }, align 8
@144 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 23, [6 x i8] undef }, align 8
@145 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 23, [6 x i8] undef }, align 8
@146 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@147 = private unnamed_addr constant %"array_list.Aligned(debug.Dwarf.FileEntry,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@148 = private unnamed_addr constant [16 x i8] zeroinitializer, align 1
@149 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@150 = private unnamed_addr constant %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false)" { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data)" { ptr undef, i64 0, i64 0 }, ptr null, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@151 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@__anon_7187 = internal unnamed_addr constant [56 x i8] c"source and destination arguments have non-equal lengths\00", align 1
@__anon_7192 = internal unnamed_addr constant [24 x i8] c"@memcpy arguments alias\00", align 1
@__anon_7247 = internal unnamed_addr constant [28 x i8] c"Unable to dump stack trace: ", align 1
@152 = private unnamed_addr constant [1 x i8] c"s", align 1
@153 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@154 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@Progress.stderr_mutex = internal unnamed_addr global %Thread.Mutex.Recursive { i64 0, %Thread.Mutex zeroinitializer, i32 -1, [4 x i8] undef }, align 8
@Progress.stderr_file_writer = internal unnamed_addr global %fs.File.Writer { i64 0, %Io.Writer { ptr @__anon_18137, { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, %fs.File { i32 2 }, i16 0, i16 0, i16 0, i16 0, i16 0, i3 0, [1 x i8] undef }, align 8
@Thread.LinuxThreadImpl.tls_thread_id = internal thread_local unnamed_addr global { i32, i8, [3 x i8] } { i32 undef, i8 0, [3 x i8] undef }, align 4
@__anon_7420 = internal unnamed_addr constant [7 x i8] c"format\00", align 1
@155 = private unnamed_addr constant [1 x i64] [i64 -1], align 8
@__anon_7499 = internal unnamed_addr constant [17 x i8] c"division by zero\00", align 1
@__anon_7515 = internal unnamed_addr constant [1 x i8] c"(", align 1
@156 = private unnamed_addr constant [1 x i8] c"d", align 1
@157 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6580, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@158 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_7565 = internal unnamed_addr constant [37 x i8] c" additional stack frames skipped...)\0A", align 1
@159 = private unnamed_addr constant %heap.arena_allocator.ArenaAllocator.State zeroinitializer, align 8
@__anon_7589 = internal unnamed_addr constant %mem.Allocator.VTable { ptr @heap.arena_allocator.ArenaAllocator.alloc, ptr @heap.arena_allocator.ArenaAllocator.resize, ptr @heap.arena_allocator.ArenaAllocator.remap, ptr @heap.arena_allocator.ArenaAllocator.free }, align 8
@160 = private unnamed_addr constant { i1, i8 } { i1 false, i8 1 }, align 1
@161 = private unnamed_addr constant { i1, i8 } { i1 true, i8 1 }, align 1
@162 = private unnamed_addr constant { i1, i8 } { i1 undef, i8 0 }, align 1
@__anon_7623 = internal unnamed_addr constant [16 x i8] c"(msg truncated)\00", align 1
@163 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr inttoptr (i64 -8 to ptr), i16 0, [6 x i8] undef }, align 8
@164 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@165 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@166 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@167 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 66, i8 undef, [1 x i8] undef }, align 2
@168 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@169 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 106, [6 x i8] undef }, align 8
@170 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@171 = private unnamed_addr constant { %debug.Dwarf.call_frame.Instruction, i16, [6 x i8] } { %debug.Dwarf.call_frame.Instruction undef, i16 69, [6 x i8] undef }, align 8
@172 = private unnamed_addr constant { %debug.Dwarf.call_frame.Instruction, i16, [6 x i8] } { %debug.Dwarf.call_frame.Instruction undef, i16 107, [6 x i8] undef }, align 8
@173 = private unnamed_addr constant { %debug.Dwarf.call_frame.Instruction, i16, [6 x i8] } { %debug.Dwarf.call_frame.Instruction undef, i16 108, [6 x i8] undef }, align 8
@174 = private unnamed_addr constant { [16 x i8], i4, [7 x i8] } { [16 x i8] undef, i4 0, [7 x i8] undef }, align 8
@175 = private unnamed_addr constant { %debug.SelfInfo.VirtualMachine.Row, i16, [6 x i8] } { %debug.SelfInfo.VirtualMachine.Row undef, i16 109, [6 x i8] undef }, align 8
@176 = private unnamed_addr constant { %debug.SelfInfo.VirtualMachine.Row, i16, [6 x i8] } { %debug.SelfInfo.VirtualMachine.Row undef, i16 105, [6 x i8] undef }, align 8
@177 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@178 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 103, [6 x i8] undef }, align 8
@179 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@180 = private unnamed_addr constant { %debug.Dwarf.ExceptionFrameHeader, i8, [7 x i8] } { %debug.Dwarf.ExceptionFrameHeader undef, i8 0, [7 x i8] undef }, align 8
@181 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 104, [6 x i8] undef }, align 8
@182 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 110, [6 x i8] undef }, align 8
@183 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 125, [6 x i8] undef }, align 8
@184 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 126, [6 x i8] undef }, align 8
@185 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 127, [6 x i8] undef }, align 8
@186 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@187 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 23, [6 x i8] undef }, align 8
@188 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@189 = private unnamed_addr constant { %debug.StackIterator.getLastError__struct_5143, i8, [7 x i8] } { %debug.StackIterator.getLastError__struct_5143 undef, i8 0, [7 x i8] undef }, align 8
@__anon_8252 = internal unnamed_addr constant [24 x i8] c"Unwind information for `", align 1
@190 = private unnamed_addr constant [1 x i8] c"s", align 1
@191 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@192 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_8267 = internal unnamed_addr constant [3 x i8] c":0x", align 1
@193 = private unnamed_addr constant [1 x i8] c"x", align 1
@194 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6671, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@__anon_8329 = internal unnamed_addr constant [46 x i8] c"` was not available, trace may be incomplete\0A\0A", align 1
@__anon_8372 = internal unnamed_addr constant [25 x i8] c"Unwind error at address `", align 1
@195 = private unnamed_addr constant [1 x i8] c"s", align 1
@196 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@197 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@198 = private unnamed_addr constant [1 x i8] c"x", align 1
@199 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6671, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@__anon_8399 = internal unnamed_addr constant [3 x i8] c"` (", align 1
@200 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@__anon_8441 = internal unnamed_addr constant [28 x i8] c"), trace may be incomplete\0A\0A", align 1
@__anon_111 = internal unnamed_addr constant i8 0, align 1
@201 = private unnamed_addr constant { %dynamic_library.LinkMap.Iterator, i16, [6 x i8] } { %dynamic_library.LinkMap.Iterator undef, i16 81, [6 x i8] undef }, align 8
@202 = private unnamed_addr constant { i16, [4096 x i8] } { i16 39, [4096 x i8] undef }, align 2
@203 = private unnamed_addr constant { %fs.File.Stat, i16, [14 x i8] } { %fs.File.Stat undef, i16 6, [14 x i8] undef }, align 16
@204 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@205 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 66, [6 x i8] undef }, align 8
@__anon_8834 = internal unnamed_addr constant %Io.Reader.VTable { ptr @Io.Reader.endingStream, ptr @Io.Reader.endingDiscard, ptr @Io.Reader.endingReadVec, ptr @Io.Reader.endingRebase }, align 8
@compress.flate.Decompress.direct_vtable = internal unnamed_addr constant %Io.Reader.VTable { ptr @compress.flate.Decompress.streamDirect, ptr @compress.flate.Decompress.discardDirect, ptr @compress.flate.Decompress.readVec, ptr @compress.flate.Decompress.rebaseFallible }, align 8
@compress.flate.Decompress.indirect_vtable = internal unnamed_addr constant %Io.Reader.VTable { ptr @compress.flate.Decompress.streamIndirect, ptr @compress.flate.Decompress.discardIndirect, ptr @compress.flate.Decompress.readVec, ptr @compress.flate.Decompress.rebaseFallible }, align 8
@206 = private unnamed_addr constant { [2 x i8], i4, [1 x i8] } { [2 x i8] undef, i4 0, [1 x i8] undef }, align 2
@207 = private unnamed_addr constant %"array_list.Aligned(u8,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@208 = private unnamed_addr constant %"array_list.Aligned(u8,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@os.environ = internal unnamed_addr global { ptr, i64 } undef, align 8
@209 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 31, [6 x i8] undef }, align 8
@210 = private unnamed_addr constant %fs.File.OpenFlags zeroinitializer, align 1
@211 = private unnamed_addr constant { %debug.Dwarf.ElfModule, i16, [6 x i8] } { %debug.Dwarf.ElfModule undef, i16 66, [6 x i8] undef }, align 8
@212 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 49, [6 x i8] undef }, align 8
@213 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 49, [6 x i8] undef }, align 8
@214 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 68, [2 x i8] undef }, align 4
@215 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 68, [6 x i8] undef }, align 8
@216 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@217 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 17, [6 x i8] undef }, align 8
@218 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 14, [6 x i8] undef }, align 8
@219 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 15, [6 x i8] undef }, align 8
@220 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 12, [6 x i8] undef }, align 8
@221 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@222 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 7, [6 x i8] undef }, align 8
@223 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 6, [6 x i8] undef }, align 8
@224 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 13, [6 x i8] undef }, align 8
@225 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 10, [6 x i8] undef }, align 8
@226 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 11, [6 x i8] undef }, align 8
@227 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__anon_10362 = internal unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.Discarding.drain, ptr @Io.Writer.Discarding.sendFile, ptr @Io.Writer.defaultFlush, ptr @Io.Writer.defaultRebase }, align 8
@228 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@229 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 1, [6 x i8] undef }, align 8
@230 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@231 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@232 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 67, [6 x i8] undef }, align 8
@233 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@234 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 67, [6 x i8] undef }, align 8
@235 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@236 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 66 }, align 2
@237 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@238 = private unnamed_addr constant { i32, i8, [3 x i8] } { i32 undef, i8 0, [3 x i8] undef }, align 4
@239 = private unnamed_addr constant { i32, i8, [3 x i8] } { i32 undef, i8 0, [3 x i8] undef }, align 4
@240 = private unnamed_addr constant { i32, i8, [3 x i8] } { i32 undef, i8 0, [3 x i8] undef }, align 4
@241 = private unnamed_addr constant %"array_list.Aligned(debug.Dwarf.FileEntry,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@242 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@243 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@244 = private unnamed_addr constant [1 x i64] zeroinitializer, align 8
@Progress.global_progress = internal unnamed_addr global %Progress { { %Thread, i8, [7 x i8] } { %Thread undef, i8 0, [7 x i8] undef }, i64 undef, i64 undef, { ptr, i64 } undef, { ptr, i64 } { ptr @Progress.node_parents_buffer, i64 83 }, { ptr, i64 } { ptr @Progress.node_storage_buffer, i64 83 }, { ptr, i64 } { ptr @Progress.node_freelist_next_buffer, i64 83 }, %fs.File undef, %Thread.ResetEvent zeroinitializer, i32 255, i32 0, i16 0, i16 0, i2 0, i1 false, i1 false, i2 0 }, align 8
@__anon_10685 = internal unnamed_addr constant [12 x i8] c"\1B[J\1B]9;4;0\07\00", align 1
@245 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@246 = private unnamed_addr constant %builtin.Type.Int { i16 32, i1 true, [1 x i8] undef }, align 2
@__anon_7599 = internal unnamed_addr constant [9 x i8] c"NO_COLOR\00", align 1
@__anon_7606 = internal unnamed_addr constant [15 x i8] c"CLICOLOR_FORCE\00", align 1
@__anon_10795 = internal unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.fixedDrain, ptr @Io.Writer.unimplementedSendFile, ptr @Io.Writer.noopFlush, ptr @Io.Writer.failingRebase }, align 8
@__anon_10837 = internal unnamed_addr constant [27 x i8] c"index out of bounds: index ", align 1
@247 = private unnamed_addr constant [1 x i8] c"d", align 1
@248 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6580, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@249 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_10855 = internal unnamed_addr constant [6 x i8] c", len ", align 1
@250 = private unnamed_addr constant [4 x i8] c"cie\00", align 1
@251 = private unnamed_addr constant [4 x i8] c"fde\00", align 1
@252 = private unnamed_addr constant [11 x i8] c"terminator\00", align 1
@253 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@254 = private unnamed_addr constant { i64, { { [16 x i8], i4, [7 x i8] }, { i8, i8 }, [6 x i8] }, %debug.SelfInfo.VirtualMachine.ColumnRange, i1, [7 x i8] } { i64 0, { { [16 x i8], i4, [7 x i8] }, { i8, i8 }, [6 x i8] } { { [16 x i8], i4, [7 x i8] } { [16 x i8] undef, i4 0, [7 x i8] undef }, { i8, i8 } { i8 undef, i8 0 }, [6 x i8] undef }, %debug.SelfInfo.VirtualMachine.ColumnRange { i64 undef, i8 0, [7 x i8] undef }, i1 false, [7 x i8] undef }, align 8
@255 = private unnamed_addr constant { %debug.SelfInfo.VirtualMachine.Row, i8, [7 x i8] } { %debug.SelfInfo.VirtualMachine.Row undef, i8 0, [7 x i8] undef }, align 8
@256 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 3, i8 undef, [1 x i8] undef }, align 2
@__anon_10904 = internal unnamed_addr constant [19 x i8] c"invalid error code\00", align 1
@__anon_10908 = internal unnamed_addr constant [19 x i8] c"invalid enum value\00", align 1
@257 = private unnamed_addr constant { %debug.SelfInfo.VirtualMachine.ColumnRange, i8, [7 x i8] } { %debug.SelfInfo.VirtualMachine.ColumnRange undef, i8 0, [7 x i8] undef }, align 8
@258 = private unnamed_addr constant { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value", i8, [7 x i8] }, i16, [6 x i8] } { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value", i8, [7 x i8] } { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value" undef, i8 0, [7 x i8] undef }, i16 0, [6 x i8] undef }, align 8
@259 = private unnamed_addr constant [8 x i8] c"generic\00", align 1
@260 = private unnamed_addr constant [12 x i8] c"regval_type\00", align 1
@261 = private unnamed_addr constant [11 x i8] c"const_type\00", align 1
@262 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__anon_11405 = internal unnamed_addr constant [12 x i8] c"start index ", align 1
@263 = private unnamed_addr constant [1 x i8] c"d", align 1
@264 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6580, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@265 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_11444 = internal unnamed_addr constant [26 x i8] c" is larger than end index ", align 1
@_DYNAMIC = extern_weak hidden constant %elf.Elf64_Dyn, align 8
@266 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 42, [2 x i8] undef }, align 4
@267 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 16, [2 x i8] undef }, align 4
@268 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 48, [2 x i8] undef }, align 4
@269 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 7, [2 x i8] undef }, align 4
@270 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 45, [2 x i8] undef }, align 4
@271 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 46, [2 x i8] undef }, align 4
@272 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 39, [2 x i8] undef }, align 4
@273 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 47, [2 x i8] undef }, align 4
@274 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 38, [2 x i8] undef }, align 4
@275 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 36, [2 x i8] undef }, align 4
@276 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 17, [2 x i8] undef }, align 4
@277 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 6, [2 x i8] undef }, align 4
@278 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 49, [2 x i8] undef }, align 4
@279 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 50, [2 x i8] undef }, align 4
@280 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 20, [2 x i8] undef }, align 4
@281 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 35, [2 x i8] undef }, align 4
@282 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 51, [2 x i8] undef }, align 4
@283 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 52, [2 x i8] undef }, align 4
@284 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 14, [2 x i8] undef }, align 4
@285 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 53, [2 x i8] undef }, align 4
@286 = private unnamed_addr constant %"hash.crc.impl.Crc(u32,.{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 })" { i32 -1 }, align 4
@287 = private unnamed_addr constant [256 x i32] [i32 0, i32 1996959894, i32 -301047508, i32 -1727442502, i32 124634137, i32 1886057615, i32 -379345611, i32 -1637575261, i32 249268274, i32 2044508324, i32 -522852066, i32 -1747789432, i32 162941995, i32 2125561021, i32 -407360249, i32 -1866523247, i32 498536548, i32 1789927666, i32 -205950648, i32 -2067906082, i32 450548861, i32 1843258603, i32 -187386543, i32 -2083289657, i32 325883990, i32 1684777152, i32 -43845254, i32 -1973040660, i32 335633487, i32 1661365465, i32 -99664541, i32 -1928851979, i32 997073096, i32 1281953886, i32 -715111964, i32 -1570279054, i32 1006888145, i32 1258607687, i32 -770865667, i32 -1526024853, i32 901097722, i32 1119000684, i32 -608450090, i32 -1396901568, i32 853044451, i32 1172266101, i32 -589951537, i32 -1412350631, i32 651767980, i32 1373503546, i32 -925412992, i32 -1076862698, i32 565507253, i32 1454621731, i32 -809855591, i32 -1195530993, i32 671266974, i32 1594198024, i32 -972236366, i32 -1324619484, i32 795835527, i32 1483230225, i32 -1050600021, i32 -1234817731, i32 1994146192, i32 31158534, i32 -1731059524, i32 -271249366, i32 1907459465, i32 112637215, i32 -1614814043, i32 -390540237, i32 2013776290, i32 251722036, i32 -1777751922, i32 -519137256, i32 2137656763, i32 141376813, i32 -1855689577, i32 -429695999, i32 1802195444, i32 476864866, i32 -2056965928, i32 -228458418, i32 1812370925, i32 453092731, i32 -2113342271, i32 -183516073, i32 1706088902, i32 314042704, i32 -1950435094, i32 -54949764, i32 1658658271, i32 366619977, i32 -1932296973, i32 -69972891, i32 1303535960, i32 984961486, i32 -1547960204, i32 -725929758, i32 1256170817, i32 1037604311, i32 -1529756563, i32 -740887301, i32 1131014506, i32 879679996, i32 -1385723834, i32 -631195440, i32 1141124467, i32 855842277, i32 -1442165665, i32 -586318647, i32 1342533948, i32 654459306, i32 -1106571248, i32 -921952122, i32 1466479909, i32 544179635, i32 -1184443383, i32 -832445281, i32 1591671054, i32 702138776, i32 -1328506846, i32 -942167884, i32 1504918807, i32 783551873, i32 -1212326853, i32 -1061524307, i32 -306674912, i32 -1698712650, i32 62317068, i32 1957810842, i32 -355121351, i32 -1647151185, i32 81470997, i32 1943803523, i32 -480048366, i32 -1805370492, i32 225274430, i32 2053790376, i32 -468791541, i32 -1828061283, i32 167816743, i32 2097651377, i32 -267414716, i32 -2029476910, i32 503444072, i32 1762050814, i32 -144550051, i32 -2140837941, i32 426522225, i32 1852507879, i32 -19653770, i32 -1982649376, i32 282753626, i32 1742555852, i32 -105259153, i32 -1900089351, i32 397917763, i32 1622183637, i32 -690576408, i32 -1580100738, i32 953729732, i32 1340076626, i32 -776247311, i32 -1497606297, i32 1068828381, i32 1219638859, i32 -670225446, i32 -1358292148, i32 906185462, i32 1090812512, i32 -547295293, i32 -1469587627, i32 829329135, i32 1181335161, i32 -882789492, i32 -1134132454, i32 628085408, i32 1382605366, i32 -871598187, i32 -1156888829, i32 570562233, i32 1426400815, i32 -977650754, i32 -1296233688, i32 733239954, i32 1555261956, i32 -1026031705, i32 -1244606671, i32 752459403, i32 1541320221, i32 -1687895376, i32 -328994266, i32 1969922972, i32 40735498, i32 -1677130071, i32 -351390145, i32 1913087877, i32 83908371, i32 -1782625662, i32 -491226604, i32 2075208622, i32 213261112, i32 -1831694693, i32 -438977011, i32 2094854071, i32 198958881, i32 -2032938284, i32 -237706686, i32 1759359992, i32 534414190, i32 -2118248755, i32 -155638181, i32 1873836001, i32 414664567, i32 -2012718362, i32 -15766928, i32 1711684554, i32 285281116, i32 -1889165569, i32 -127750551, i32 1634467795, i32 376229701, i32 -1609899400, i32 -686959890, i32 1308918612, i32 956543938, i32 -1486412191, i32 -799009033, i32 1231636301, i32 1047427035, i32 -1362007478, i32 -640263460, i32 1088359270, i32 936918000, i32 -1447252397, i32 -558129467, i32 1202900863, i32 817233897, i32 -1111625188, i32 -893730166, i32 1404277552, i32 615818150, i32 -1160759803, i32 -841546093, i32 1423857449, i32 601450431, i32 -1285129682, i32 -1000256840, i32 1567103746, i32 711928724, i32 -1274298825, i32 -1022587231, i32 1510334235, i32 755167117], align 4
@288 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@289 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@290 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@291 = private unnamed_addr constant %compress.flate.Container.Metadata__struct_6008 zeroinitializer, align 4
@292 = private unnamed_addr constant %compress.flate.Container.Metadata__struct_6009 zeroinitializer, align 4
@293 = private unnamed_addr constant { [8 x i8], i2, [3 x i8] } { [8 x i8] undef, i2 0, [3 x i8] undef }, align 4
@Io.Writer.Allocating.vtable = internal unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.Allocating.drain, ptr @Io.Writer.Allocating.sendFile, ptr @Io.Writer.noopFlush, ptr @Io.Writer.Allocating.growingRebase }, align 8
@294 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@295 = private unnamed_addr constant [1 x i8] c"x", align 1
@296 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6671, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@297 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_13840 = internal unnamed_addr constant [10 x i8] c"/debuginfo", align 1
@298 = private unnamed_addr constant [1 x i8] c"x", align 1
@299 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6671, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@300 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@301 = private unnamed_addr constant [1 x i8] c"x", align 1
@302 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6671, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@303 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_13927 = internal unnamed_addr constant [6 x i8] c".debug", align 1
@__anon_14000 = internal unnamed_addr constant i32 2623488, align 4
@304 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@305 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 23, [6 x i8] undef }, align 8
@306 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@307 = private unnamed_addr constant { %debug.Dwarf.PcRange, i8, [7 x i8] } { %debug.Dwarf.PcRange undef, i8 0, [7 x i8] undef }, align 8
@308 = private unnamed_addr constant { %debug.Dwarf.CompileUnit.SrcLocCache, i8, [7 x i8] } { %debug.Dwarf.CompileUnit.SrcLocCache undef, i8 0, [7 x i8] undef }, align 8
@309 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@310 = private unnamed_addr constant { %debug.Dwarf.PcRange, i8, [7 x i8] } { %debug.Dwarf.PcRange undef, i8 0, [7 x i8] undef }, align 8
@311 = private unnamed_addr constant { %debug.Dwarf.CompileUnit.SrcLocCache, i8, [7 x i8] } { %debug.Dwarf.CompileUnit.SrcLocCache undef, i8 0, [7 x i8] undef }, align 8
@312 = private unnamed_addr constant { i32, i8, [3 x i8] } { i32 undef, i8 0, [3 x i8] undef }, align 4
@313 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@314 = private unnamed_addr constant { %debug.Dwarf.CommonInformationEntry, i8, [7 x i8] } { %debug.Dwarf.CommonInformationEntry undef, i8 0, [7 x i8] undef }, align 8
@315 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@316 = private unnamed_addr constant { i4, i8 } { i4 undef, i8 0 }, align 1
@317 = private unnamed_addr constant { i3, i8 } { i3 undef, i8 0 }, align 1
@318 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@319 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@320 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 4, [6 x i8] undef }, align 8
@321 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 31, [6 x i8] undef }, align 8
@322 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 67, i8 undef, [1 x i8] undef }, align 2
@323 = private unnamed_addr constant { i24, i16, [2 x i8] } { i24 undef, i16 67, [2 x i8] undef }, align 4
@324 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@325 = private unnamed_addr constant [3 x i64] [i64 8, i64 12, i64 0], align 8
@326 = private unnamed_addr constant [3 x i64] [i64 1, i64 2, i64 0], align 8
@327 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@328 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr inttoptr (i64 -1 to ptr), i16 0, [6 x i8] undef }, align 8
@329 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@330 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@331 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 78, [6 x i8] undef }, align 8
@332 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 17, [6 x i8] undef }, align 8
@333 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 14, [6 x i8] undef }, align 8
@334 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 79, [6 x i8] undef }, align 8
@335 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 77, [6 x i8] undef }, align 8
@336 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 48, [6 x i8] undef }, align 8
@337 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@338 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 49, [6 x i8] undef }, align 8
@339 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 16, [6 x i8] undef }, align 8
@340 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 20, [6 x i8] undef }, align 8
@341 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 9, [6 x i8] undef }, align 8
@342 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 10, [6 x i8] undef }, align 8
@343 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 51, [6 x i8] undef }, align 8
@344 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 38, [6 x i8] undef }, align 8
@345 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 80, [6 x i8] undef }, align 8
@__anon_14872 = internal unnamed_addr constant [18 x i8] c"Deadlock detected\00", align 1
@346 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__anon_14890 = internal unnamed_addr constant [201 x i8] c"00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899\00", align 1
@347 = private unnamed_addr constant %SinglyLinkedList.Node zeroinitializer, align 8
@__anon_14926 = internal unnamed_addr constant [5 x i8] c"TERM\00", align 1
@__anon_14929 = internal unnamed_addr constant [5 x i8] c"dumb\00", align 1
@348 = private unnamed_addr constant { i8, i8 } { i8 undef, i8 0 }, align 1
@349 = private unnamed_addr constant { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand", i8, [7 x i8] }, i16, [6 x i8] } { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand", i8, [7 x i8] } undef, i16 118, [6 x i8] undef }, align 8
@350 = private unnamed_addr constant { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand", i8, [7 x i8] }, i16, [6 x i8] } { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand", i8, [7 x i8] } undef, i16 107, [6 x i8] undef }, align 8
@351 = private unnamed_addr constant { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand", i8, [7 x i8] }, i16, [6 x i8] } { { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand", i8, [7 x i8] } { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand" undef, i8 0, [7 x i8] undef }, i16 0, [6 x i8] undef }, align 8
@352 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 120, [6 x i8] undef }, align 8
@353 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 123, [6 x i8] undef }, align 8
@354 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 124, [6 x i8] undef }, align 8
@355 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@356 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 117, i1 undef, [1 x i8] undef }, align 2
@357 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 116, i1 undef, [1 x i8] undef }, align 2
@358 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 112, i1 undef, [1 x i8] undef }, align 2
@359 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 119, i1 undef, [1 x i8] undef }, align 2
@360 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 118, i1 undef, [1 x i8] undef }, align 2
@361 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 114, i1 undef, [1 x i8] undef }, align 2
@362 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 121, i1 undef, [1 x i8] undef }, align 2
@363 = private unnamed_addr constant %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true })" { %"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 } }, align 8
@364 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@365 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 113, i1 undef, [1 x i8] undef }, align 2
@366 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 111, i1 undef, [1 x i8] undef }, align 2
@367 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 115, i1 undef, [1 x i8] undef }, align 2
@debug.MemoryAccessor.cached_pid = internal unnamed_addr global i32 -1, align 4
@368 = private unnamed_addr constant %fs.File.OpenFlags zeroinitializer, align 1
@__anon_15466 = internal unnamed_addr constant [7 x i8] c"error.\00", align 1
@__anon_15510 = internal unnamed_addr constant [25 x i8] c"attempt to unwrap error: ", align 1
@369 = private unnamed_addr constant [1 x i8] c"s", align 1
@370 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@371 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@372 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@__anon_15593 = internal unnamed_addr constant [18 x i8] c"unexpected errno: ", align 1
@373 = private unnamed_addr constant [1 x i8] c"d", align 1
@374 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6580, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@375 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@376 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 16, [6 x i8] undef }, align 8
@377 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 56, [6 x i8] undef }, align 8
@378 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 55, [6 x i8] undef }, align 8
@379 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 45, [6 x i8] undef }, align 8
@380 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 39, [6 x i8] undef }, align 8
@381 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 36, [6 x i8] undef }, align 8
@382 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 6, [6 x i8] undef }, align 8
@383 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 50, [6 x i8] undef }, align 8
@384 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 42, [2 x i8] undef }, align 4
@385 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 16, [2 x i8] undef }, align 4
@386 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 48, [2 x i8] undef }, align 4
@387 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 7, [2 x i8] undef }, align 4
@388 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 45, [2 x i8] undef }, align 4
@389 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 46, [2 x i8] undef }, align 4
@390 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 39, [2 x i8] undef }, align 4
@391 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 47, [2 x i8] undef }, align 4
@392 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 38, [2 x i8] undef }, align 4
@393 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 36, [2 x i8] undef }, align 4
@394 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 17, [2 x i8] undef }, align 4
@395 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 6, [2 x i8] undef }, align 4
@396 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 49, [2 x i8] undef }, align 4
@397 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 50, [2 x i8] undef }, align 4
@398 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 20, [2 x i8] undef }, align 4
@399 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 35, [2 x i8] undef }, align 4
@400 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 51, [2 x i8] undef }, align 4
@401 = private unnamed_addr constant { i7, i8 } { i7 undef, i8 0 }, align 1
@402 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@403 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@404 = private unnamed_addr constant { { %debug.Dwarf.Die, i8, [7 x i8] }, i16, [6 x i8] } { { %debug.Dwarf.Die, i8, [7 x i8] } { %debug.Dwarf.Die undef, i8 0, [7 x i8] undef }, i16 0, [6 x i8] undef }, align 8
@405 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@406 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@407 = private unnamed_addr constant %"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)" { ptr null, i32 0, i32 0, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@408 = private unnamed_addr constant %debug.SafetyLock zeroinitializer, align 1
@409 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@410 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 21, [6 x i8] undef }, align 8
@__anon_16109 = internal unnamed_addr constant [28 x i8] c"sentinel mismatch: expected ", align 1
@411 = private unnamed_addr constant [3 x i8] c"any", align 1
@__anon_16118 = internal unnamed_addr constant [3 x i8] c"any", align 1
@412 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_16118, i64 3 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@413 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_16145 = internal unnamed_addr constant [8 x i8] c", found ", align 1
@414 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@__anon_16388 = internal unnamed_addr constant [23 x i8] c"access of union field '", align 1
@415 = private unnamed_addr constant [1 x i8] c"s", align 1
@416 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_4173, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@417 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_16416 = internal unnamed_addr constant [15 x i8] c"' while field '", align 1
@__anon_16439 = internal unnamed_addr constant [11 x i8] c"' is active", align 1
@418 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@419 = private unnamed_addr constant %builtin.Type.Int { i16 32, i1 true, [1 x i8] undef }, align 2
@420 = private unnamed_addr constant %builtin.Type.Int { i16 8, i1 false, [1 x i8] undef }, align 2
@421 = private unnamed_addr constant %builtin.Type.Int { i16 16, i1 false, [1 x i8] undef }, align 2
@422 = private unnamed_addr constant %builtin.Type.Int { i16 32, i1 false, [1 x i8] undef }, align 2
@423 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 false, [1 x i8] undef }, align 2
@424 = private unnamed_addr constant %builtin.Type.Int { i16 8, i1 true, [1 x i8] undef }, align 2
@425 = private unnamed_addr constant %builtin.Type.Int { i16 16, i1 true, [1 x i8] undef }, align 2
@426 = private unnamed_addr constant [8 x i8] c"generic\00", align 1
@427 = private unnamed_addr constant [9 x i8] c"register\00", align 1
@428 = private unnamed_addr constant [10 x i8] c"type_size\00", align 1
@429 = private unnamed_addr constant [14 x i8] c"branch_offset\00", align 1
@430 = private unnamed_addr constant [14 x i8] c"base_register\00", align 1
@431 = private unnamed_addr constant [19 x i8] c"composite_location\00", align 1
@432 = private unnamed_addr constant [6 x i8] c"block\00", align 1
@433 = private unnamed_addr constant [14 x i8] c"register_type\00", align 1
@434 = private unnamed_addr constant [11 x i8] c"const_type\00", align 1
@435 = private unnamed_addr constant [11 x i8] c"deref_type\00", align 1
@436 = private unnamed_addr constant { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value", i8, [7 x i8] } { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value" undef, i8 0, [7 x i8] undef }, align 8
@437 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@438 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@439 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@440 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@441 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 false, [1 x i8] undef }, align 2
@442 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 undef, i8 0, [1 x i8] undef }, align 2
@443 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@444 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@445 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 49, [6 x i8] undef }, align 8
@__anon_16553 = internal unnamed_addr constant [34 x i8] c"exact division produced remainder\00", align 1
@__anon_16577 = internal unnamed_addr constant [17 x i8] c"0123456789ABCDEF\00", align 1
@__anon_16579 = internal unnamed_addr constant [17 x i8] c"0123456789abcdef\00", align 1
@446 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@447 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@448 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@__anon_16677 = internal unnamed_addr constant [45 x i8] c"for loop over objects with non-equal lengths\00", align 1
@449 = private unnamed_addr constant [3 x i64] [i64 8, i64 96, i64 0], align 8
@450 = private unnamed_addr constant [3 x i64] [i64 1, i64 2, i64 0], align 8
@451 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@452 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@453 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@454 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@455 = private unnamed_addr constant %builtin.Type.Int { i16 32, i1 true, [1 x i8] undef }, align 2
@456 = private unnamed_addr constant { i32, i16, [2 x i8] } { i32 undef, i16 66, [2 x i8] undef }, align 4
@457 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@458 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@459 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@460 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@__anon_15337 = internal unnamed_addr constant [6 x i8] c"/proc/", align 1
@461 = private unnamed_addr constant [1 x i8] c"d", align 1
@462 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6580, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@463 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_15429 = internal unnamed_addr constant [4 x i8] c"/mem", align 1
@464 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@465 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 17, [6 x i8] undef }, align 8
@466 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 14, [6 x i8] undef }, align 8
@467 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 12, [6 x i8] undef }, align 8
@468 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@469 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 7, [6 x i8] undef }, align 8
@470 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 6, [6 x i8] undef }, align 8
@471 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 13, [6 x i8] undef }, align 8
@472 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 10, [6 x i8] undef }, align 8
@473 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 11, [6 x i8] undef }, align 8
@474 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 22, [6 x i8] undef }, align 8
@475 = private unnamed_addr constant %builtin.Type.Int { i16 16, i1 true, [1 x i8] undef }, align 2
@476 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 49, [6 x i8] undef }, align 8
@477 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@478 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@479 = private unnamed_addr constant [33 x i32] [i32 0, i32 1, i32 2, i32 4, i32 9, i32 19, i32 38, i32 76, i32 153, i32 307, i32 614, i32 1228, i32 2457, i32 4915, i32 9830, i32 19660, i32 39321, i32 78643, i32 157286, i32 314572, i32 629145, i32 1258291, i32 2516582, i32 5033164, i32 10066329, i32 20132659, i32 40265318, i32 80530636, i32 161061273, i32 322122547, i32 644245094, i32 1288490188, i32 -1], align 4
@480 = private unnamed_addr constant { i16, i8, [1 x i8] } { i16 31, i8 undef, [1 x i8] undef }, align 2
@481 = private unnamed_addr constant [33 x i32] [i32 0, i32 1, i32 2, i32 4, i32 9, i32 19, i32 38, i32 76, i32 153, i32 307, i32 614, i32 1228, i32 2457, i32 4915, i32 9830, i32 19660, i32 39321, i32 78643, i32 157286, i32 314572, i32 629145, i32 1258291, i32 2516582, i32 5033164, i32 10066329, i32 20132659, i32 40265318, i32 80530636, i32 161061273, i32 322122547, i32 644245094, i32 1288490188, i32 -1], align 4
@482 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@483 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@484 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@485 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@486 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@487 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@488 = private unnamed_addr constant { i6, i8 } { i6 3, i8 1 }, align 1
@489 = private unnamed_addr constant %hash.wyhash.Wyhash { i64 undef, i64 undef, [3 x i64] undef, i64 0, i64 0, [48 x i8] undef }, align 8
@490 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 17, [6 x i8] undef }, align 8
@491 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 14, [6 x i8] undef }, align 8
@492 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 12, [6 x i8] undef }, align 8
@493 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@494 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 7, [6 x i8] undef }, align 8
@495 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 6, [6 x i8] undef }, align 8
@496 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 13, [6 x i8] undef }, align 8
@497 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 10, [6 x i8] undef }, align 8
@498 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 11, [6 x i8] undef }, align 8
@499 = private unnamed_addr constant %builtin.Type.Int { i16 8, i1 true, [1 x i8] undef }, align 2
@500 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@501 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 true, [1 x i8] undef }, align 2
@502 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@__anon_17526 = internal unnamed_addr constant [14 x i8] c"/proc/self/fd/", align 1
@503 = private unnamed_addr constant [1 x i8] c"d", align 1
@504 = private unnamed_addr constant { { ptr, i64 }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, { [16 x i8], i2, [7 x i8] }, i8, i2, [6 x i8] } { { ptr, i64 } { ptr @__anon_6580, i64 1 }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, { [16 x i8], i2, [7 x i8] } { [16 x i8] undef, i2 0, [7 x i8] undef }, i8 32, i2 -2, [6 x i8] undef }, align 8
@505 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@506 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@507 = private unnamed_addr constant { i6, i8 } { i6 2, i8 1 }, align 1
@__anon_17608 = internal unnamed_addr constant [43 x i8] c"shift amount is greater than the type size\00", align 1
@508 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@509 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@510 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@511 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@512 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@513 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@514 = private unnamed_addr constant %builtin.Type.Int { i16 64, i1 false, [1 x i8] undef }, align 2
@515 = private unnamed_addr constant %builtin.Type.Int { i16 32, i1 false, [1 x i8] undef }, align 2
@516 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@517 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@518 = private unnamed_addr constant { i6, i8 } { i6 undef, i8 0 }, align 1
@519 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@520 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@521 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@522 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@523 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@524 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr inttoptr (i64 -4 to ptr), i16 0, [6 x i8] undef }, align 8
@525 = private unnamed_addr constant { ptr, i16, [6 x i8] } { ptr undef, i16 31, [6 x i8] undef }, align 8
@builtin.zig_backend = internal unnamed_addr constant i64 2, align 8
@start.simplified_logic = internal unnamed_addr constant i1 false, align 1
@builtin.output_mode = internal unnamed_addr constant i2 -2, align 1
@builtin.os = internal unnamed_addr constant %Target.Os { %Target.Os.VersionRange { %Target.Os.LinuxVersionRange { %SemanticVersion.Range { %SemanticVersion { i64 5, i64 10, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, %SemanticVersion { i64 6, i64 16, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer } }, %SemanticVersion { i64 2, i64 31, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, i32 29, [4 x i8] undef }, i3 3, [7 x i8] undef }, i6 8, [7 x i8] undef }, align 8
@builtin.mode = internal unnamed_addr constant i2 0, align 1
@debug.runtime_safety = internal unnamed_addr constant i1 true, align 1
@debug.native_os = internal unnamed_addr constant i6 8, align 1
@debug.have_segfault_handling_support = internal unnamed_addr constant i1 true, align 1
@debug.default_enable_segfault_handler = internal unnamed_addr constant i1 true, align 1
@log.default_level = internal unnamed_addr constant i2 -1, align 1
@std.options = internal unnamed_addr constant %std.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i64 3, i1 true, i2 -1, i1 false, i1 true, i1 false, i1 false, i1 true, i2 -2 }, align 8
@debug.enable_segfault_handler = internal unnamed_addr constant i1 true, align 1
@builtin.link_libc = internal unnamed_addr constant i1 false, align 1
@posix.native_os = internal unnamed_addr constant i6 8, align 1
@posix.use_libc = internal unnamed_addr constant i1 false, align 1
@builtin.single_threaded = internal unnamed_addr constant i1 false, align 1
@Thread.native_os = internal unnamed_addr constant i6 8, align 1
@Target.Cpu.Feature.Set.empty = internal unnamed_addr constant %Target.Cpu.Feature.Set zeroinitializer, align 8
@builtin.cpu = internal unnamed_addr constant %Target.Cpu { ptr @Target.x86.cpu.x86_64, %Target.Cpu.Feature.Set { [5 x i64] [i64 1224979098644774928, i64 1153343856658350080, i64 211119117434880, i64 17, i64 0] }, i6 -22, [7 x i8] undef }, align 8
@Target.x86.cpu.x86_64 = internal unnamed_addr constant %Target.Cpu.Model { { ptr, i64 } { ptr @__anon_17896, i64 6 }, { ptr, i64 } { ptr @__anon_17898, i64 6 }, %Target.Cpu.Feature.Set { [5 x i64] [i64 1224979098644774928, i64 1153343856658350080, i64 140750373257216, i64 17, i64 0] } }, align 8
@builtin.abi = internal unnamed_addr constant i5 15, align 1
@builtin.object_format = internal unnamed_addr constant i4 2, align 1
@Target.DynamicLinker.none = internal unnamed_addr constant %Target.DynamicLinker { [255 x i8] undef, i8 0 }, align 1
@builtin.target = internal unnamed_addr constant %Target { %Target.Cpu { ptr @Target.x86.cpu.x86_64, %Target.Cpu.Feature.Set { [5 x i64] [i64 1224979098644774928, i64 1153343856658350080, i64 211119117434880, i64 17, i64 0] }, i6 -22, [7 x i8] undef }, %Target.Os { %Target.Os.VersionRange { %Target.Os.LinuxVersionRange { %SemanticVersion.Range { %SemanticVersion { i64 5, i64 10, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, %SemanticVersion { i64 6, i64 16, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer } }, %SemanticVersion { i64 2, i64 31, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, i32 29, [4 x i8] undef }, i3 3, [7 x i8] undef }, i6 8, [7 x i8] undef }, i5 15, i4 2, %Target.DynamicLinker { [255 x i8] [i8 47, i8 108, i8 105, i8 98, i8 47, i8 108, i8 100, i8 45, i8 109, i8 117, i8 115, i8 108, i8 45, i8 120, i8 56, i8 54, i8 95, i8 54, i8 52, i8 46, i8 115, i8 111, i8 46, i8 49, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef], i8 24 }, [6 x i8] undef }, align 8
@builtin.strip_debug_info = internal unnamed_addr constant i1 false, align 1
@debug.SelfInfo.native_os = internal unnamed_addr constant i6 8, align 1
@"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80).Metadata.free" = internal unnamed_addr constant i7 0, align 1
@Io.tty.native_os = internal unnamed_addr constant i6 8, align 1
@os.linux.native_arch = internal unnamed_addr constant i6 -22, align 1
@debug.have_ucontext = internal unnamed_addr constant i1 true, align 1
@os.linux.is_mips = internal unnamed_addr constant i1 false, align 1
@debug.have_getcontext = internal unnamed_addr constant i1 true, align 1
@debug.MemoryAccessor.native_os = internal unnamed_addr constant i6 8, align 1
@debug.Dwarf.expression.native_arch = internal unnamed_addr constant i6 -22, align 1
@debug.Dwarf.expression.native_endian = internal unnamed_addr constant i1 true, align 1
@debug.SelfInfo.supports_unwinding = internal unnamed_addr constant i1 true, align 1
@debug.SelfInfo.native_arch = internal unnamed_addr constant i6 -22, align 1
@debug.SelfInfo.ip_reg_num = internal unnamed_addr constant i8 16, align 1
@"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@debug.MemoryAccessor.init = internal unnamed_addr constant %debug.MemoryAccessor { %fs.File { i32 -1 } }, align 4
@heap.page_size_min_default = internal unnamed_addr constant { i64, i8, [7 x i8] } { i64 4096, i8 1, [7 x i8] undef }, align 8
@heap.page_size_min = internal unnamed_addr constant i64 4096, align 8
@debug.SelfInfo.native_endian = internal unnamed_addr constant i1 true, align 1
@mem.native_endian = internal unnamed_addr constant i1 true, align 1
@debug.Dwarf.null_section_array = internal unnamed_addr constant [14 x { %debug.Dwarf.Section, i8, [7 x i8] }] [{ %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }, { %debug.Dwarf.Section, i8, [7 x i8] } { %debug.Dwarf.Section undef, i8 0, [7 x i8] undef }], align 8
@posix.page_size_min = internal unnamed_addr constant i64 4096, align 8
@"array_list.Aligned(debug.Dwarf.Abbrev.Table,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.Dwarf.Abbrev.Table,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@"array_list.Aligned(debug.Dwarf.CompileUnit,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.Dwarf.CompileUnit,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@"array_list.Aligned(debug.Dwarf.Func,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.Dwarf.Func,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).empty" = internal unnamed_addr constant %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false)" { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data)" { ptr undef, i64 0, i64 0 }, ptr null, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@"array_list.Aligned(debug.Dwarf.Range,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.Dwarf.Range,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@debug.Dwarf.native_endian = internal unnamed_addr constant i1 true, align 1
@fs.path.native_os = internal unnamed_addr constant i6 8, align 1
@fs.path.sep_posix = internal unnamed_addr constant i8 47, align 1
@fs.path.sep = internal unnamed_addr constant i8 47, align 1
@builtin.CallingConvention.c = internal unnamed_addr constant { <{ %builtin.CallingConvention.CommonOptions, [8 x i8] }>, i8, [7 x i8] } { <{ %builtin.CallingConvention.CommonOptions, [8 x i8] }> <{ %builtin.CallingConvention.CommonOptions { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef } }, [8 x i8] undef }>, i8 4, [7 x i8] undef }, align 8
@os.linux.is_sparc = internal unnamed_addr constant i1 false, align 1
@os.linux.SIG__struct_3836.DFL = internal unnamed_addr constant ptr null, align 8
@Thread.use_pthreads = internal unnamed_addr constant i1 false, align 1
@mem.use_vectors = internal unnamed_addr constant i1 true, align 1
@builtin.fuzz = internal unnamed_addr constant i1 false, align 1
@mem.use_vectors_for_comparison = internal unnamed_addr constant i1 true, align 1
@"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80).empty" = internal unnamed_addr constant %"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)" { ptr null, i32 0, i32 0, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@heap.next_mmap_addr_hint = internal unnamed_addr global ptr null, align 8
@526 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 60, [6 x i8] undef }, align 8
@527 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 149, [6 x i8] undef }, align 8
@528 = private unnamed_addr constant { { ptr, i64 }, i16, [6 x i8] } { { ptr, i64 } undef, i16 31, [6 x i8] undef }, align 8
@529 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 0, i8 1, [7 x i8] undef }, align 8
@530 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@heap.page_allocator = internal unnamed_addr constant %mem.Allocator { ptr undef, ptr @heap.PageAllocator.vtable }, align 8
@fs.File.native_os = internal unnamed_addr constant i6 8, align 1
@fs.File.is_windows = internal unnamed_addr constant i1 false, align 1
@debug.native_arch = internal unnamed_addr constant i6 -22, align 1
@elf.MAGIC = internal unnamed_addr constant ptr @__anon_5480, align 8
@fs.native_os = internal unnamed_addr constant i6 8, align 1
@fs.Dir.native_os = internal unnamed_addr constant i6 8, align 1
@posix.lfs64_abi = internal unnamed_addr constant i1 false, align 1
@Io.Reader.native_endian = internal unnamed_addr constant i1 true, align 1
@"array_list.Aligned(u8,null).empty" = internal unnamed_addr constant %"array_list.Aligned(u8,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@debug.Dwarf.debug_debug_mode = internal unnamed_addr constant i1 false, align 1
@"array_list.Aligned(debug.Dwarf.FileEntry,null).empty" = internal unnamed_addr constant %"array_list.Aligned(debug.Dwarf.FileEntry,null)" { { ptr, i64 } { ptr inttoptr (i64 -6148914691236517206 to ptr), i64 0 }, i64 0 }, align 8
@Progress.is_windows = internal unnamed_addr constant i1 false, align 1
@Thread.Mutex.FutexImpl.unlocked = internal unnamed_addr constant i32 0, align 4
@Thread.Mutex.Recursive.invalid_thread_id = internal unnamed_addr constant i32 -1, align 4
@Thread.Mutex.Recursive.init = internal unnamed_addr constant %Thread.Mutex.Recursive { i64 0, %Thread.Mutex zeroinitializer, i32 -1, [4 x i8] undef }, align 8
@531 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@532 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@533 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@534 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 1, [6 x i8] undef }, align 8
@535 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 4, [6 x i8] undef }, align 8
@536 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@537 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 1, [6 x i8] undef }, align 8
@538 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@539 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@540 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 9, [6 x i8] undef }, align 8
@541 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 95, [6 x i8] undef }, align 8
@542 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 14, [6 x i8] undef }, align 8
@543 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@544 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 6, [6 x i8] undef }, align 8
@545 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 22, [6 x i8] undef }, align 8
@546 = private unnamed_addr constant %SemanticVersion { i64 2, i64 27, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, align 8
@547 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 96, [6 x i8] undef }, align 8
@548 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 48, [6 x i8] undef }, align 8
@549 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 98, [6 x i8] undef }, align 8
@550 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@551 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 7, [6 x i8] undef }, align 8
@552 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 31, [6 x i8] undef }, align 8
@553 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 49, [6 x i8] undef }, align 8
@554 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 100, [6 x i8] undef }, align 8
@555 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 66, [6 x i8] undef }, align 8
@556 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 20, [6 x i8] undef }, align 8
@557 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 101, [6 x i8] undef }, align 8
@558 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 102, [6 x i8] undef }, align 8
@559 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 78, [6 x i8] undef }, align 8
@560 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 17, [6 x i8] undef }, align 8
@561 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 14, [6 x i8] undef }, align 8
@562 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 79, [6 x i8] undef }, align 8
@563 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 77, [6 x i8] undef }, align 8
@564 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 48, [6 x i8] undef }, align 8
@565 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@566 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 49, [6 x i8] undef }, align 8
@567 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 20, [6 x i8] undef }, align 8
@568 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 9, [6 x i8] undef }, align 8
@569 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 22, [6 x i8] undef }, align 8
@570 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 51, [6 x i8] undef }, align 8
@571 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 78, [6 x i8] undef }, align 8
@572 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 17, [6 x i8] undef }, align 8
@573 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 14, [6 x i8] undef }, align 8
@574 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 79, [6 x i8] undef }, align 8
@575 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 77, [6 x i8] undef }, align 8
@576 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 48, [6 x i8] undef }, align 8
@577 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@578 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 49, [6 x i8] undef }, align 8
@579 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 20, [6 x i8] undef }, align 8
@580 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 9, [6 x i8] undef }, align 8
@581 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 10, [6 x i8] undef }, align 8
@582 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 51, [6 x i8] undef }, align 8
@__anon_18311 = internal unnamed_addr constant [18 x i8] c"invalid API usage\00", align 1
@583 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8
@Progress.stderr_writer = internal unnamed_addr constant ptr getelementptr inbounds (i8, ptr @Progress.stderr_file_writer, i64 8), align 8
@Io.Writer.ANY = internal unnamed_addr constant ptr @__anon_7409, align 8
@__anon_7409 = internal unnamed_addr constant [4 x i8] c"any\00", align 1
@debug.Dwarf.call_frame.Opcode.lo_inline = internal unnamed_addr constant i8 64, align 1
@debug.Dwarf.call_frame.Opcode.hi_inline = internal unnamed_addr constant i8 -1, align 1
@debug.Dwarf.call_frame.Opcode.lo_reserved = internal unnamed_addr constant i8 0, align 1
@debug.Dwarf.call_frame.Opcode.hi_reserved = internal unnamed_addr constant i8 22, align 1
@builtin.omit_frame_pointer = internal unnamed_addr constant i1 false, align 1
@process.native_os = internal unnamed_addr constant i6 8, align 1
@os.linux.extern_getauxval = internal unnamed_addr constant i1 true, align 1
@fs.Dir.have_flock = internal unnamed_addr constant i1 true, align 1
@posix.unexpected_error_tracing = internal unnamed_addr constant i1 true, align 1
@584 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@585 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@586 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@587 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@588 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 1, [6 x i8] undef }, align 8
@__anon_18400 = internal unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.unreachableDrain, ptr @Io.Writer.unimplementedSendFile, ptr @Io.Writer.defaultFlush, ptr @Io.Writer.unreachableRebase }, align 8
@589 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@590 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 3, i1 undef, [1 x i8] undef }, align 2
@591 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 2, i1 undef, [1 x i8] undef }, align 2
@592 = private unnamed_addr constant { i16, i1, [1 x i8] } { i16 2, i1 undef, [1 x i8] undef }, align 2
@593 = private unnamed_addr constant { i16, i2, [1 x i8] } { i16 3, i2 undef, [1 x i8] undef }, align 2
@594 = private unnamed_addr constant { i16, i2, [1 x i8] } { i16 2, i2 undef, [1 x i8] undef }, align 2
@595 = private unnamed_addr constant { i16, i2, [1 x i8] } { i16 2, i2 undef, [1 x i8] undef }, align 2
@596 = private unnamed_addr constant { i16, i5, [1 x i8] } { i16 3, i5 undef, [1 x i8] undef }, align 2
@597 = private unnamed_addr constant { i16, i5, [1 x i8] } { i16 2, i5 undef, [1 x i8] undef }, align 2
@598 = private unnamed_addr constant { i16, i5, [1 x i8] } { i16 2, i5 undef, [1 x i8] undef }, align 2
@599 = private unnamed_addr constant { i16, i4, [1 x i8] } { i16 3, i4 undef, [1 x i8] undef }, align 2
@600 = private unnamed_addr constant { i16, i4, [1 x i8] } { i16 2, i4 undef, [1 x i8] undef }, align 2
@601 = private unnamed_addr constant { i16, i4, [1 x i8] } { i16 2, i4 undef, [1 x i8] undef }, align 2
@602 = private unnamed_addr constant { i16, i3, [1 x i8] } { i16 3, i3 undef, [1 x i8] undef }, align 2
@603 = private unnamed_addr constant { i16, i3, [1 x i8] } { i16 2, i3 undef, [1 x i8] undef }, align 2
@604 = private unnamed_addr constant { i16, i3, [1 x i8] } { i16 2, i3 undef, [1 x i8] undef }, align 2
@605 = private unnamed_addr constant [8 x i16] zeroinitializer, align 2
@606 = private unnamed_addr constant { i16, i7, [1 x i8] } { i16 2, i7 undef, [1 x i8] undef }, align 2
@607 = private unnamed_addr constant { i16, i7, [1 x i8] } { i16 3, i7 undef, [1 x i8] undef }, align 2
@608 = private unnamed_addr constant { i16, i7, [1 x i8] } { i16 2, i7 undef, [1 x i8] undef }, align 2
@609 = private unnamed_addr constant { i46, i16, [6 x i8] } { i46 undef, i16 87, [6 x i8] undef }, align 8
@610 = private unnamed_addr constant { i16, i7, [1 x i8] } { i16 3, i7 undef, [1 x i8] undef }, align 2
@611 = private unnamed_addr constant { i16, i7, [1 x i8] } { i16 2, i7 undef, [1 x i8] undef }, align 2
@612 = private unnamed_addr constant { i16, i7, [1 x i8] } { i16 2, i7 undef, [1 x i8] undef }, align 2
@613 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 91, [6 x i8] undef }, align 8
@614 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 1, i16 0, [6 x i8] undef }, align 8
@615 = private unnamed_addr constant [16 x i16] zeroinitializer, align 2
@616 = private unnamed_addr constant [16 x i16] zeroinitializer, align 2
@617 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 2 }, align 2
@618 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 3 }, align 2
@619 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 2 }, align 2
@620 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 87 }, align 2
@621 = private unnamed_addr constant { i16, i16 } { i16 undef, i16 87 }, align 2
@622 = private unnamed_addr constant { i15, i16 } { i15 undef, i16 2 }, align 2
@623 = private unnamed_addr constant { i15, i16 } { i15 undef, i16 3 }, align 2
@624 = private unnamed_addr constant { i15, i16 } { i15 undef, i16 2 }, align 2
@625 = private unnamed_addr constant { i46, i16, [6 x i8] } { i46 undef, i16 87, [6 x i8] undef }, align 8
@626 = private unnamed_addr constant { i46, i16, [6 x i8] } { i46 undef, i16 87, [6 x i8] undef }, align 8
@__jmptab_1412 = internal unnamed_addr global [9 x ptr] [ptr blockaddress(@compress.flate.Decompress.streamInner, %Case), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case1), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case2), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case3), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case4), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case5), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case6), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case7), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case8)]
@627 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 82, [6 x i8] undef }, align 8
@628 = private unnamed_addr constant { [2 x i8], i4, [1 x i8] } { [2 x i8] undef, i4 1, [1 x i8] undef }, align 2
@629 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 83, [6 x i8] undef }, align 8
@630 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 89, [6 x i8] undef }, align 8
@631 = private unnamed_addr constant { [2 x i8], i4, [1 x i8] } { [2 x i8] undef, i4 3, [1 x i8] undef }, align 2
@632 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 91, [6 x i8] undef }, align 8
@633 = private unnamed_addr constant [19 x i4] zeroinitializer, align 1
@compress.flate.HuffmanEncoder.codegen_order = internal unnamed_addr constant [19 x i32] [i32 16, i32 17, i32 18, i32 0, i32 8, i32 7, i32 9, i32 6, i32 10, i32 5, i32 11, i32 4, i32 12, i32 3, i32 13, i32 2, i32 14, i32 1, i32 15], align 4
@634 = private unnamed_addr constant [316 x i4] zeroinitializer, align 1
@635 = private unnamed_addr constant { [2 x i8], i4, [1 x i8] } { [2 x i8] undef, i4 4, [1 x i8] undef }, align 2
@636 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 90, [6 x i8] undef }, align 8
@637 = private unnamed_addr constant { [2 x i8], i4, [1 x i8] } { [2 x i8] undef, i4 7, [1 x i8] undef }, align 2
@638 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 87, [6 x i8] undef }, align 8
@__jmptab_1111 = internal unnamed_addr global [3 x ptr] [ptr blockaddress(@compress.flate.Decompress.streamInner, %Case19), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case21), ptr blockaddress(@compress.flate.Decompress.streamInner, %Case20)]
@639 = private unnamed_addr constant { [2 x i8], i4, [1 x i8] } { [2 x i8] undef, i4 -8, [1 x i8] undef }, align 2
@640 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@641 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@642 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@643 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@644 = private unnamed_addr constant [29 x %compress.flate.Token.MatchLength] [%compress.flate.Token.MatchLength { i16 257, i16 3, i8 0, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 258, i16 4, i8 1, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 259, i16 5, i8 2, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 260, i16 6, i8 3, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 261, i16 7, i8 4, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 262, i16 8, i8 5, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 263, i16 9, i8 6, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 264, i16 10, i8 7, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 265, i16 11, i8 8, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 266, i16 13, i8 10, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 267, i16 15, i8 12, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 268, i16 17, i8 14, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 269, i16 19, i8 16, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 270, i16 23, i8 20, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 271, i16 27, i8 24, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 272, i16 31, i8 28, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 273, i16 35, i8 32, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 274, i16 43, i8 40, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 275, i16 51, i8 48, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 276, i16 59, i8 56, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 277, i16 67, i8 64, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 278, i16 83, i8 80, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 279, i16 99, i8 96, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 280, i16 115, i8 112, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 281, i16 131, i8 -128, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 282, i16 163, i8 -96, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 283, i16 195, i8 -64, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 284, i16 227, i8 -32, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 285, i16 258, i8 -1, i8 0, i4 0, [1 x i8] undef }], align 2
@645 = private unnamed_addr constant [30 x %compress.flate.Token.MatchDistance] [%compress.flate.Token.MatchDistance { i16 0, i16 1, i16 0, i8 0, i4 0 }, %compress.flate.Token.MatchDistance { i16 1, i16 2, i16 0, i8 1, i4 0 }, %compress.flate.Token.MatchDistance { i16 2, i16 3, i16 0, i8 2, i4 0 }, %compress.flate.Token.MatchDistance { i16 3, i16 4, i16 0, i8 3, i4 0 }, %compress.flate.Token.MatchDistance { i16 4, i16 5, i16 0, i8 4, i4 1 }, %compress.flate.Token.MatchDistance { i16 6, i16 7, i16 0, i8 5, i4 1 }, %compress.flate.Token.MatchDistance { i16 8, i16 9, i16 0, i8 6, i4 2 }, %compress.flate.Token.MatchDistance { i16 12, i16 13, i16 0, i8 7, i4 2 }, %compress.flate.Token.MatchDistance { i16 16, i16 17, i16 0, i8 8, i4 3 }, %compress.flate.Token.MatchDistance { i16 24, i16 25, i16 0, i8 9, i4 3 }, %compress.flate.Token.MatchDistance { i16 32, i16 33, i16 0, i8 10, i4 4 }, %compress.flate.Token.MatchDistance { i16 48, i16 49, i16 0, i8 11, i4 4 }, %compress.flate.Token.MatchDistance { i16 64, i16 65, i16 0, i8 12, i4 5 }, %compress.flate.Token.MatchDistance { i16 96, i16 97, i16 0, i8 13, i4 5 }, %compress.flate.Token.MatchDistance { i16 128, i16 129, i16 0, i8 14, i4 6 }, %compress.flate.Token.MatchDistance { i16 192, i16 193, i16 0, i8 15, i4 6 }, %compress.flate.Token.MatchDistance { i16 256, i16 257, i16 0, i8 16, i4 7 }, %compress.flate.Token.MatchDistance { i16 384, i16 385, i16 0, i8 17, i4 7 }, %compress.flate.Token.MatchDistance { i16 512, i16 513, i16 0, i8 18, i4 -8 }, %compress.flate.Token.MatchDistance { i16 768, i16 769, i16 0, i8 19, i4 -8 }, %compress.flate.Token.MatchDistance { i16 1024, i16 1025, i16 0, i8 20, i4 -7 }, %compress.flate.Token.MatchDistance { i16 1536, i16 1537, i16 0, i8 21, i4 -7 }, %compress.flate.Token.MatchDistance { i16 2048, i16 2049, i16 0, i8 22, i4 -6 }, %compress.flate.Token.MatchDistance { i16 3072, i16 3073, i16 0, i8 23, i4 -6 }, %compress.flate.Token.MatchDistance { i16 4096, i16 4097, i16 0, i8 24, i4 -5 }, %compress.flate.Token.MatchDistance { i16 6144, i16 6145, i16 0, i8 25, i4 -5 }, %compress.flate.Token.MatchDistance { i16 8192, i16 8193, i16 0, i8 26, i4 -4 }, %compress.flate.Token.MatchDistance { i16 12288, i16 12289, i16 0, i8 27, i4 -4 }, %compress.flate.Token.MatchDistance { i16 16384, i16 16385, i16 0, i8 28, i4 -3 }, %compress.flate.Token.MatchDistance { i16 24576, i16 24577, i16 0, i8 29, i4 -3 }], align 2
@646 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@647 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@648 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 150, [6 x i8] undef }, align 8
@__anon_19272 = internal unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.unreachableDrain, ptr @Io.Writer.unimplementedSendFile, ptr @Io.Writer.defaultFlush, ptr @Io.Writer.defaultRebase }, align 8
@net.native_os = internal unnamed_addr constant i6 8, align 1
@net.has_unix_sockets = internal unnamed_addr constant i1 true, align 1
@Progress.have_ipc = internal unnamed_addr constant i1 true, align 1
@process.Child.native_os = internal unnamed_addr constant i6 8, align 1
@process.Child.ResourceUsageStatistics.rusage_init = internal unnamed_addr constant { %os.linux.rusage, i8, [7 x i8] } { %os.linux.rusage undef, i8 0, [7 x i8] undef }, align 8
@Io.is_windows = internal unnamed_addr constant i1 false, align 1
@"array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true).empty" = internal unnamed_addr constant %"array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true)" { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true).Data)" { ptr undef, i64 0, i64 0 }, ptr null, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@"array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true).empty" = internal unnamed_addr constant %"array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true)" { %"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true).Data)" { ptr undef, i64 0, i64 0 }, ptr null, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@"hash_map.HashMapUnmanaged(Build.InitializedDepKey,*Build.Dependency,Build.InitializedDepContext,80).empty" = internal unnamed_addr constant %"hash_map.HashMapUnmanaged(Build.InitializedDepKey,*Build.Dependency,Build.InitializedDepContext,80)" { ptr null, i32 0, i32 0, %debug.SafetyLock zeroinitializer, [7 x i8] undef }, align 8
@Build.Cache.hasher_init = internal unnamed_addr constant %"crypto.siphash.SipHash(u128,1,3)" { %"crypto.siphash.SipHashStateless(u128,1,3)" { i64 2610252333708293958, i64 333165314171327618, i64 4264751251528818770, i64 1483287458198707826, i8 0, [7 x i8] undef }, i64 0, [8 x i8] undef }, align 8
@"hash_map.HashMapUnmanaged([]const u8,[]const u8,process.EnvMap.EnvNameHashContext,80).Metadata.free" = internal unnamed_addr constant i7 0, align 1
@"hash_map.HashMapUnmanaged(Build.InitializedDepKey,*Build.Dependency,Build.InitializedDepContext,80).Metadata.free" = internal unnamed_addr constant i7 0, align 1
@"hash_map.HashMapUnmanaged([]const u8,void,hash_map.StringContext,80).Metadata.free" = internal unnamed_addr constant i7 0, align 1
@Progress.Node.none = internal unnamed_addr constant %Progress.Node { i8 -1 }, align 1
@"hash_map.HashMapUnmanaged([]const u8,Build.UserInputOption,hash_map.StringContext,80).Metadata.free" = internal unnamed_addr constant i7 0, align 1
@"hash_map.HashMapUnmanaged([]const u8,Build.AvailableOption,hash_map.StringContext,80).Metadata.free" = internal unnamed_addr constant i7 0, align 1
@builtin.valgrind_support = internal unnamed_addr constant i1 true, align 1
@Progress.noop_impl = internal unnamed_addr constant i1 false, align 1
@Progress.node_parents_buffer = internal unnamed_addr global [83 x i8] undef, align 1
@Progress.node_storage_buffer = internal unnamed_addr global [83 x %Progress.Node.Storage] undef, align 8
@Progress.node_freelist_next_buffer = internal unnamed_addr global [83 x i8] undef, align 1
@Progress.clear = internal unnamed_addr constant ptr @__anon_10678, align 8
@__anon_10678 = internal unnamed_addr constant [4 x i8] c"\1B[J\00", align 1
@Progress.progress_remove = internal unnamed_addr constant ptr @__anon_10681, align 8
@__anon_10681 = internal unnamed_addr constant [9 x i8] c"\1B]9;4;0\07\00", align 1
@heap.arena_allocator.ArenaAllocator.BufNode_alignment = internal unnamed_addr constant i6 3, align 1
@"hash.crc.impl.Crc(u32,.{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 }).lookup_table" = internal unnamed_addr constant [256 x i32] [i32 0, i32 1996959894, i32 -301047508, i32 -1727442502, i32 124634137, i32 1886057615, i32 -379345611, i32 -1637575261, i32 249268274, i32 2044508324, i32 -522852066, i32 -1747789432, i32 162941995, i32 2125561021, i32 -407360249, i32 -1866523247, i32 498536548, i32 1789927666, i32 -205950648, i32 -2067906082, i32 450548861, i32 1843258603, i32 -187386543, i32 -2083289657, i32 325883990, i32 1684777152, i32 -43845254, i32 -1973040660, i32 335633487, i32 1661365465, i32 -99664541, i32 -1928851979, i32 997073096, i32 1281953886, i32 -715111964, i32 -1570279054, i32 1006888145, i32 1258607687, i32 -770865667, i32 -1526024853, i32 901097722, i32 1119000684, i32 -608450090, i32 -1396901568, i32 853044451, i32 1172266101, i32 -589951537, i32 -1412350631, i32 651767980, i32 1373503546, i32 -925412992, i32 -1076862698, i32 565507253, i32 1454621731, i32 -809855591, i32 -1195530993, i32 671266974, i32 1594198024, i32 -972236366, i32 -1324619484, i32 795835527, i32 1483230225, i32 -1050600021, i32 -1234817731, i32 1994146192, i32 31158534, i32 -1731059524, i32 -271249366, i32 1907459465, i32 112637215, i32 -1614814043, i32 -390540237, i32 2013776290, i32 251722036, i32 -1777751922, i32 -519137256, i32 2137656763, i32 141376813, i32 -1855689577, i32 -429695999, i32 1802195444, i32 476864866, i32 -2056965928, i32 -228458418, i32 1812370925, i32 453092731, i32 -2113342271, i32 -183516073, i32 1706088902, i32 314042704, i32 -1950435094, i32 -54949764, i32 1658658271, i32 366619977, i32 -1932296973, i32 -69972891, i32 1303535960, i32 984961486, i32 -1547960204, i32 -725929758, i32 1256170817, i32 1037604311, i32 -1529756563, i32 -740887301, i32 1131014506, i32 879679996, i32 -1385723834, i32 -631195440, i32 1141124467, i32 855842277, i32 -1442165665, i32 -586318647, i32 1342533948, i32 654459306, i32 -1106571248, i32 -921952122, i32 1466479909, i32 544179635, i32 -1184443383, i32 -832445281, i32 1591671054, i32 702138776, i32 -1328506846, i32 -942167884, i32 1504918807, i32 783551873, i32 -1212326853, i32 -1061524307, i32 -306674912, i32 -1698712650, i32 62317068, i32 1957810842, i32 -355121351, i32 -1647151185, i32 81470997, i32 1943803523, i32 -480048366, i32 -1805370492, i32 225274430, i32 2053790376, i32 -468791541, i32 -1828061283, i32 167816743, i32 2097651377, i32 -267414716, i32 -2029476910, i32 503444072, i32 1762050814, i32 -144550051, i32 -2140837941, i32 426522225, i32 1852507879, i32 -19653770, i32 -1982649376, i32 282753626, i32 1742555852, i32 -105259153, i32 -1900089351, i32 397917763, i32 1622183637, i32 -690576408, i32 -1580100738, i32 953729732, i32 1340076626, i32 -776247311, i32 -1497606297, i32 1068828381, i32 1219638859, i32 -670225446, i32 -1358292148, i32 906185462, i32 1090812512, i32 -547295293, i32 -1469587627, i32 829329135, i32 1181335161, i32 -882789492, i32 -1134132454, i32 628085408, i32 1382605366, i32 -871598187, i32 -1156888829, i32 570562233, i32 1426400815, i32 -977650754, i32 -1296233688, i32 733239954, i32 1555261956, i32 -1026031705, i32 -1244606671, i32 752459403, i32 1541320221, i32 -1687895376, i32 -328994266, i32 1969922972, i32 40735498, i32 -1677130071, i32 -351390145, i32 1913087877, i32 83908371, i32 -1782625662, i32 -491226604, i32 2075208622, i32 213261112, i32 -1831694693, i32 -438977011, i32 2094854071, i32 198958881, i32 -2032938284, i32 -237706686, i32 1759359992, i32 534414190, i32 -2118248755, i32 -155638181, i32 1873836001, i32 414664567, i32 -2012718362, i32 -15766928, i32 1711684554, i32 285281116, i32 -1889165569, i32 -127750551, i32 1634467795, i32 376229701, i32 -1609899400, i32 -686959890, i32 1308918612, i32 956543938, i32 -1486412191, i32 -799009033, i32 1231636301, i32 1047427035, i32 -1362007478, i32 -640263460, i32 1088359270, i32 936918000, i32 -1447252397, i32 -558129467, i32 1202900863, i32 817233897, i32 -1111625188, i32 -893730166, i32 1404277552, i32 615818150, i32 -1160759803, i32 -841546093, i32 1423857449, i32 601450431, i32 -1285129682, i32 -1000256840, i32 1567103746, i32 711928724, i32 -1274298825, i32 -1022587231, i32 1510334235, i32 755167117], align 4
@649 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 1, [6 x i8] undef }, align 8
@650 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@651 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 3, [6 x i8] undef }, align 8
@652 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 1, [6 x i8] undef }, align 8
@653 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@"hash_map.HashMapUnmanaged([]const u8,*const Build.UserValue,hash_map.StringContext,80).Metadata.free" = internal unnamed_addr constant i7 0, align 1
@fs.is_darwin = internal unnamed_addr constant i1 false, align 1
@os.native_os = internal unnamed_addr constant i6 8, align 1
@heap.page_size_max_default = internal unnamed_addr constant { i64, i8, [7 x i8] } { i64 4096, i8 1, [7 x i8] undef }, align 8
@heap.page_size_max = internal unnamed_addr constant i64 4096, align 8
@debug.MemoryAccessor.page_size_min = internal unnamed_addr constant i64 4096, align 8
@debug.MemoryAccessor.have_msync = internal unnamed_addr constant i1 true, align 1
@"hash_map.HashMapUnmanaged(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80).Metadata.slot_free" = internal unnamed_addr constant i8 0, align 1
@hash.wyhash.Wyhash.secret = internal unnamed_addr constant [4 x i64] [i64 -6884282663029611473, i64 -1800455987208640293, i64 -8161530843051276573, i64 6384245875588680899], align 8
@"array_hash_map.Index(u8).empty_sentinel" = internal unnamed_addr constant i8 -1, align 1
@"array_hash_map.Index(u16).empty_sentinel" = internal unnamed_addr constant i16 -1, align 2
@"array_hash_map.Index(u32).empty_sentinel" = internal unnamed_addr constant i32 -1, align 4
@Thread.Mutex.FutexImpl.contended = internal unnamed_addr constant i32 3, align 4
@Thread.Mutex.FutexImpl.locked = internal unnamed_addr constant i32 1, align 4
@os.linux.is_ppc = internal unnamed_addr constant i1 false, align 1
@array_hash_map.index_capacities = internal unnamed_addr constant [33 x i32] [i32 0, i32 1, i32 2, i32 4, i32 9, i32 19, i32 38, i32 76, i32 153, i32 307, i32 614, i32 1228, i32 2457, i32 4915, i32 9830, i32 19660, i32 39321, i32 78643, i32 157286, i32 314572, i32 629145, i32 1258291, i32 2516582, i32 5033164, i32 10066329, i32 20132659, i32 40265318, i32 80530636, i32 161061273, i32 322122547, i32 644245094, i32 1288490188, i32 -1], align 4
@os.linux.usize_bits = internal unnamed_addr constant i16 64, align 2
@__anon_17896 = internal unnamed_addr constant [7 x i8] c"x86_64\00", align 1
@__anon_17898 = internal unnamed_addr constant [7 x i8] c"x86-64\00", align 1
@heap.PageAllocator.page_size_min = internal unnamed_addr constant i64 4096, align 8
@heap.PageAllocator.native_os = internal unnamed_addr constant i6 8, align 1
@__anon_18137 = internal unnamed_addr constant %Io.Writer.VTable { ptr @fs.File.Writer.drain, ptr @fs.File.Writer.sendFile, ptr @Io.Writer.defaultFlush, ptr @Io.Writer.defaultRebase }, align 8
@os.linux.wrapped.lfs64_abi = internal unnamed_addr constant i1 false, align 1
@compress.flate.Token.match_lengths = internal unnamed_addr constant [29 x %compress.flate.Token.MatchLength] [%compress.flate.Token.MatchLength { i16 257, i16 3, i8 0, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 258, i16 4, i8 1, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 259, i16 5, i8 2, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 260, i16 6, i8 3, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 261, i16 7, i8 4, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 262, i16 8, i8 5, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 263, i16 9, i8 6, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 264, i16 10, i8 7, i8 0, i4 0, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 265, i16 11, i8 8, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 266, i16 13, i8 10, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 267, i16 15, i8 12, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 268, i16 17, i8 14, i8 0, i4 1, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 269, i16 19, i8 16, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 270, i16 23, i8 20, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 271, i16 27, i8 24, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 272, i16 31, i8 28, i8 0, i4 2, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 273, i16 35, i8 32, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 274, i16 43, i8 40, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 275, i16 51, i8 48, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 276, i16 59, i8 56, i8 0, i4 3, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 277, i16 67, i8 64, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 278, i16 83, i8 80, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 279, i16 99, i8 96, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 280, i16 115, i8 112, i8 0, i4 4, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 281, i16 131, i8 -128, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 282, i16 163, i8 -96, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 283, i16 195, i8 -64, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 284, i16 227, i8 -32, i8 0, i4 5, [1 x i8] undef }, %compress.flate.Token.MatchLength { i16 285, i16 258, i8 -1, i8 0, i4 0, [1 x i8] undef }], align 2
@compress.flate.Token.match_distances = internal unnamed_addr constant [30 x %compress.flate.Token.MatchDistance] [%compress.flate.Token.MatchDistance { i16 0, i16 1, i16 0, i8 0, i4 0 }, %compress.flate.Token.MatchDistance { i16 1, i16 2, i16 0, i8 1, i4 0 }, %compress.flate.Token.MatchDistance { i16 2, i16 3, i16 0, i8 2, i4 0 }, %compress.flate.Token.MatchDistance { i16 3, i16 4, i16 0, i8 3, i4 0 }, %compress.flate.Token.MatchDistance { i16 4, i16 5, i16 0, i8 4, i4 1 }, %compress.flate.Token.MatchDistance { i16 6, i16 7, i16 0, i8 5, i4 1 }, %compress.flate.Token.MatchDistance { i16 8, i16 9, i16 0, i8 6, i4 2 }, %compress.flate.Token.MatchDistance { i16 12, i16 13, i16 0, i8 7, i4 2 }, %compress.flate.Token.MatchDistance { i16 16, i16 17, i16 0, i8 8, i4 3 }, %compress.flate.Token.MatchDistance { i16 24, i16 25, i16 0, i8 9, i4 3 }, %compress.flate.Token.MatchDistance { i16 32, i16 33, i16 0, i8 10, i4 4 }, %compress.flate.Token.MatchDistance { i16 48, i16 49, i16 0, i8 11, i4 4 }, %compress.flate.Token.MatchDistance { i16 64, i16 65, i16 0, i8 12, i4 5 }, %compress.flate.Token.MatchDistance { i16 96, i16 97, i16 0, i8 13, i4 5 }, %compress.flate.Token.MatchDistance { i16 128, i16 129, i16 0, i8 14, i4 6 }, %compress.flate.Token.MatchDistance { i16 192, i16 193, i16 0, i8 15, i4 6 }, %compress.flate.Token.MatchDistance { i16 256, i16 257, i16 0, i8 16, i4 7 }, %compress.flate.Token.MatchDistance { i16 384, i16 385, i16 0, i8 17, i4 7 }, %compress.flate.Token.MatchDistance { i16 512, i16 513, i16 0, i8 18, i4 -8 }, %compress.flate.Token.MatchDistance { i16 768, i16 769, i16 0, i8 19, i4 -8 }, %compress.flate.Token.MatchDistance { i16 1024, i16 1025, i16 0, i8 20, i4 -7 }, %compress.flate.Token.MatchDistance { i16 1536, i16 1537, i16 0, i8 21, i4 -7 }, %compress.flate.Token.MatchDistance { i16 2048, i16 2049, i16 0, i8 22, i4 -6 }, %compress.flate.Token.MatchDistance { i16 3072, i16 3073, i16 0, i8 23, i4 -6 }, %compress.flate.Token.MatchDistance { i16 4096, i16 4097, i16 0, i8 24, i4 -5 }, %compress.flate.Token.MatchDistance { i16 6144, i16 6145, i16 0, i8 25, i4 -5 }, %compress.flate.Token.MatchDistance { i16 8192, i16 8193, i16 0, i8 26, i4 -4 }, %compress.flate.Token.MatchDistance { i16 12288, i16 12289, i16 0, i8 27, i4 -4 }, %compress.flate.Token.MatchDistance { i16 16384, i16 16385, i16 0, i8 28, i4 -3 }, %compress.flate.Token.MatchDistance { i16 24576, i16 24577, i16 0, i8 29, i4 -3 }], align 2
@c.native_os = internal unnamed_addr constant i6 8, align 1
@654 = private unnamed_addr constant [12 x i8] c"WriteFailed\00", align 1
@655 = private unnamed_addr constant [11 x i8] c"ReadFailed\00", align 1
@656 = private unnamed_addr constant [12 x i8] c"EndOfStream\00", align 1
@657 = private unnamed_addr constant [14 x i8] c"Unimplemented\00", align 1
@658 = private unnamed_addr constant [12 x i8] c"InputOutput\00", align 1
@659 = private unnamed_addr constant [16 x i8] c"SystemResources\00", align 1
@660 = private unnamed_addr constant [6 x i8] c"IsDir\00", align 1
@661 = private unnamed_addr constant [17 x i8] c"OperationAborted\00", align 1
@662 = private unnamed_addr constant [11 x i8] c"BrokenPipe\00", align 1
@663 = private unnamed_addr constant [22 x i8] c"ConnectionResetByPeer\00", align 1
@664 = private unnamed_addr constant [19 x i8] c"ConnectionTimedOut\00", align 1
@665 = private unnamed_addr constant [18 x i8] c"NotOpenForReading\00", align 1
@666 = private unnamed_addr constant [19 x i8] c"SocketNotConnected\00", align 1
@667 = private unnamed_addr constant [11 x i8] c"WouldBlock\00", align 1
@668 = private unnamed_addr constant [9 x i8] c"Canceled\00", align 1
@669 = private unnamed_addr constant [13 x i8] c"AccessDenied\00", align 1
@670 = private unnamed_addr constant [16 x i8] c"ProcessNotFound\00", align 1
@671 = private unnamed_addr constant [14 x i8] c"LockViolation\00", align 1
@672 = private unnamed_addr constant [11 x i8] c"Unexpected\00", align 1
@673 = private unnamed_addr constant [17 x i8] c"PermissionDenied\00", align 1
@674 = private unnamed_addr constant [10 x i8] c"Streaming\00", align 1
@675 = private unnamed_addr constant [11 x i8] c"Unseekable\00", align 1
@676 = private unnamed_addr constant [17 x i8] c"MissingDebugInfo\00", align 1
@677 = private unnamed_addr constant [27 x i8] c"UnsupportedOperatingSystem\00", align 1
@678 = private unnamed_addr constant [16 x i8] c"InvalidRegister\00", align 1
@679 = private unnamed_addr constant [18 x i8] c"UnimplementedArch\00", align 1
@680 = private unnamed_addr constant [16 x i8] c"UnimplementedOs\00", align 1
@681 = private unnamed_addr constant [24 x i8] c"RegisterContextRequired\00", align 1
@682 = private unnamed_addr constant [26 x i8] c"ThreadContextNotSupported\00", align 1
@683 = private unnamed_addr constant [25 x i8] c"IncompatibleRegisterSize\00", align 1
@684 = private unnamed_addr constant [12 x i8] c"OutOfMemory\00", align 1
@685 = private unnamed_addr constant [17 x i8] c"InvalidDebugInfo\00", align 1
@686 = private unnamed_addr constant [6 x i8] c"Found\00", align 1
@687 = private unnamed_addr constant [17 x i8] c"SharingViolation\00", align 1
@688 = private unnamed_addr constant [18 x i8] c"PathAlreadyExists\00", align 1
@689 = private unnamed_addr constant [13 x i8] c"FileNotFound\00", align 1
@690 = private unnamed_addr constant [9 x i8] c"PipeBusy\00", align 1
@691 = private unnamed_addr constant [9 x i8] c"NoDevice\00", align 1
@692 = private unnamed_addr constant [12 x i8] c"NameTooLong\00", align 1
@693 = private unnamed_addr constant [12 x i8] c"InvalidUtf8\00", align 1
@694 = private unnamed_addr constant [12 x i8] c"InvalidWtf8\00", align 1
@695 = private unnamed_addr constant [12 x i8] c"BadPathName\00", align 1
@696 = private unnamed_addr constant [16 x i8] c"NetworkNotFound\00", align 1
@697 = private unnamed_addr constant [22 x i8] c"AntivirusInterference\00", align 1
@698 = private unnamed_addr constant [12 x i8] c"SymLinkLoop\00", align 1
@699 = private unnamed_addr constant [23 x i8] c"ProcessFdQuotaExceeded\00", align 1
@700 = private unnamed_addr constant [22 x i8] c"SystemFdQuotaExceeded\00", align 1
@701 = private unnamed_addr constant [11 x i8] c"FileTooBig\00", align 1
@702 = private unnamed_addr constant [12 x i8] c"NoSpaceLeft\00", align 1
@703 = private unnamed_addr constant [7 x i8] c"NotDir\00", align 1
@704 = private unnamed_addr constant [11 x i8] c"DeviceBusy\00", align 1
@705 = private unnamed_addr constant [22 x i8] c"FileLocksNotSupported\00", align 1
@706 = private unnamed_addr constant [9 x i8] c"FileBusy\00", align 1
@707 = private unnamed_addr constant [13 x i8] c"NotSupported\00", align 1
@708 = private unnamed_addr constant [11 x i8] c"FileSystem\00", align 1
@709 = private unnamed_addr constant [8 x i8] c"NotLink\00", align 1
@710 = private unnamed_addr constant [19 x i8] c"UnrecognizedVolume\00", align 1
@711 = private unnamed_addr constant [12 x i8] c"UnknownName\00", align 1
@712 = private unnamed_addr constant [26 x i8] c"MemoryMappingNotSupported\00", align 1
@713 = private unnamed_addr constant [26 x i8] c"LockedMemoryLimitExceeded\00", align 1
@714 = private unnamed_addr constant [21 x i8] c"MappingAlreadyExists\00", align 1
@715 = private unnamed_addr constant [16 x i8] c"InvalidElfMagic\00", align 1
@716 = private unnamed_addr constant [18 x i8] c"InvalidElfVersion\00", align 1
@717 = private unnamed_addr constant [17 x i8] c"InvalidElfEndian\00", align 1
@718 = private unnamed_addr constant [32 x i8] c"UnimplementedDwarfForeignEndian\00", align 1
@719 = private unnamed_addr constant [9 x i8] c"Overflow\00", align 1
@720 = private unnamed_addr constant [12 x i8] c"EndOfBuffer\00", align 1
@721 = private unnamed_addr constant [14 x i8] c"InvalidBuffer\00", align 1
@722 = private unnamed_addr constant [16 x i8] c"InvalidAddrSize\00", align 1
@723 = private unnamed_addr constant [24 x i8] c"PointerBaseNotSpecified\00", align 1
@724 = private unnamed_addr constant [21 x i8] c"NonNativeIndirection\00", align 1
@725 = private unnamed_addr constant [16 x i8] c"PointerOverflow\00", align 1
@726 = private unnamed_addr constant [20 x i8] c"UnsupportedAddrSize\00", align 1
@727 = private unnamed_addr constant [24 x i8] c"UnsupportedDwarfVersion\00", align 1
@728 = private unnamed_addr constant [24 x i8] c"UnsupportedDwarfSection\00", align 1
@729 = private unnamed_addr constant [10 x i8] c"EndOfFile\00", align 1
@730 = private unnamed_addr constant [10 x i8] c"DiskQuota\00", align 1
@731 = private unnamed_addr constant [16 x i8] c"InvalidArgument\00", align 1
@732 = private unnamed_addr constant [18 x i8] c"NotOpenForWriting\00", align 1
@733 = private unnamed_addr constant [14 x i8] c"MessageTooBig\00", align 1
@734 = private unnamed_addr constant [11 x i8] c"InvalidExe\00", align 1
@735 = private unnamed_addr constant [14 x i8] c"BadGzipHeader\00", align 1
@736 = private unnamed_addr constant [14 x i8] c"BadZlibHeader\00", align 1
@737 = private unnamed_addr constant [18 x i8] c"WrongGzipChecksum\00", align 1
@738 = private unnamed_addr constant [14 x i8] c"WrongGzipSize\00", align 1
@739 = private unnamed_addr constant [18 x i8] c"WrongZlibChecksum\00", align 1
@740 = private unnamed_addr constant [12 x i8] c"InvalidCode\00", align 1
@741 = private unnamed_addr constant [13 x i8] c"InvalidMatch\00", align 1
@742 = private unnamed_addr constant [21 x i8] c"WrongStoredBlockNlen\00", align 1
@743 = private unnamed_addr constant [17 x i8] c"InvalidBlockType\00", align 1
@744 = private unnamed_addr constant [26 x i8] c"InvalidDynamicBlockHeader\00", align 1
@745 = private unnamed_addr constant [26 x i8] c"OversubscribedHuffmanTree\00", align 1
@746 = private unnamed_addr constant [22 x i8] c"IncompleteHuffmanTree\00", align 1
@747 = private unnamed_addr constant [22 x i8] c"MissingEndOfBlockCode\00", align 1
@748 = private unnamed_addr constant [21 x i8] c"UnsupportedOperation\00", align 1
@749 = private unnamed_addr constant [13 x i8] c"BadFileFlags\00", align 1
@750 = private unnamed_addr constant [12 x i8] c"Interrupted\00", align 1
@751 = private unnamed_addr constant [17 x i8] c"InvalidArguments\00", align 1
@752 = private unnamed_addr constant [14 x i8] c"CorruptedData\00", align 1
@753 = private unnamed_addr constant [22 x i8] c"OperationNotSupported\00", align 1
@754 = private unnamed_addr constant [9 x i8] c"SwapFile\00", align 1
@755 = private unnamed_addr constant [18 x i8] c"NotSameFileSystem\00", align 1
@756 = private unnamed_addr constant [11 x i8] c"MissingFDE\00", align 1
@757 = private unnamed_addr constant [11 x i8] c"MissingCIE\00", align 1
@758 = private unnamed_addr constant [18 x i8] c"AddressOutOfRange\00", align 1
@759 = private unnamed_addr constant [15 x i8] c"InvalidOperand\00", align 1
@760 = private unnamed_addr constant [24 x i8] c"UnimplementedUserOpcode\00", align 1
@761 = private unnamed_addr constant [14 x i8] c"InvalidOpcode\00", align 1
@762 = private unnamed_addr constant [17 x i8] c"InvalidOperation\00", align 1
@763 = private unnamed_addr constant [15 x i8] c"InvalidCFARule\00", align 1
@764 = private unnamed_addr constant [28 x i8] c"UnimplementedExpressionCall\00", align 1
@765 = private unnamed_addr constant [20 x i8] c"UnimplementedOpcode\00", align 1
@766 = private unnamed_addr constant [29 x i8] c"UnimplementedTypedComparison\00", align 1
@767 = private unnamed_addr constant [28 x i8] c"UnimplementedTypeConversion\00", align 1
@768 = private unnamed_addr constant [24 x i8] c"UnknownExpressionOpcode\00", align 1
@769 = private unnamed_addr constant [28 x i8] c"IncompleteExpressionContext\00", align 1
@770 = private unnamed_addr constant [17 x i8] c"InvalidCFAOpcode\00", align 1
@771 = private unnamed_addr constant [18 x i8] c"InvalidExpression\00", align 1
@772 = private unnamed_addr constant [17 x i8] c"InvalidFrameBase\00", align 1
@773 = private unnamed_addr constant [24 x i8] c"InvalidIntegralTypeSize\00", align 1
@774 = private unnamed_addr constant [21 x i8] c"InvalidSubExpression\00", align 1
@775 = private unnamed_addr constant [18 x i8] c"InvalidTypeLength\00", align 1
@776 = private unnamed_addr constant [22 x i8] c"TruncatedIntegralType\00", align 1
@777 = private unnamed_addr constant [15 x i8] c"DivisionByZero\00", align 1
@778 = private unnamed_addr constant [23 x i8] c"InvalidExpressionValue\00", align 1
@779 = private unnamed_addr constant [18 x i8] c"NoExpressionValue\00", align 1
@780 = private unnamed_addr constant [11 x i8] c"InvalidCFA\00", align 1
@781 = private unnamed_addr constant [21 x i8] c"RegisterSizeMismatch\00", align 1
@782 = private unnamed_addr constant [15 x i8] c"InvalidAddress\00", align 1
@783 = private unnamed_addr constant [25 x i8] c"InvalidExpressionAddress\00", align 1
@784 = private unnamed_addr constant [26 x i8] c"UnimplementedRegisterRule\00", align 1
@785 = private unnamed_addr constant [17 x i8] c"PkgConfigCrashed\00", align 1
@786 = private unnamed_addr constant [16 x i8] c"PkgConfigFailed\00", align 1
@787 = private unnamed_addr constant [22 x i8] c"PkgConfigNotInstalled\00", align 1
@788 = private unnamed_addr constant [23 x i8] c"PkgConfigInvalidOutput\00", align 1
@789 = private unnamed_addr constant [32 x i8] c"CurrentWorkingDirectoryUnlinked\00", align 1
@790 = private unnamed_addr constant [22 x i8] c"InvalidBatchScriptArg\00", align 1
@791 = private unnamed_addr constant [21 x i8] c"ResourceLimitReached\00", align 1
@792 = private unnamed_addr constant [14 x i8] c"InvalidUserId\00", align 1
@793 = private unnamed_addr constant [19 x i8] c"ProcessAlreadyExec\00", align 1
@794 = private unnamed_addr constant [22 x i8] c"InvalidProcessGroupId\00", align 1
@795 = private unnamed_addr constant [12 x i8] c"InvalidName\00", align 1
@796 = private unnamed_addr constant [14 x i8] c"InvalidHandle\00", align 1
@797 = private unnamed_addr constant [14 x i8] c"WaitAbandoned\00", align 1
@798 = private unnamed_addr constant [12 x i8] c"WaitTimeOut\00", align 1
@799 = private unnamed_addr constant [8 x i8] c"Timeout\00", align 1
@800 = private unnamed_addr constant [28 x i8] c"UnsupportedReparsePointType\00", align 1
@801 = private unnamed_addr constant [15 x i8] c"UnmappedMemory\00", align 1
@802 = private unnamed_addr constant [25 x i8] c"InvalidSyscallParameters\00", align 1
@803 = private unnamed_addr constant [14 x i8] c"StreamTooLong\00", align 1
@804 = private unnamed_addr constant [151 x { ptr, i64 }] [{ ptr, i64 } undef, { ptr, i64 } { ptr @654, i64 11 }, { ptr, i64 } { ptr @655, i64 10 }, { ptr, i64 } { ptr @656, i64 11 }, { ptr, i64 } { ptr @657, i64 13 }, { ptr, i64 } { ptr @658, i64 11 }, { ptr, i64 } { ptr @659, i64 15 }, { ptr, i64 } { ptr @660, i64 5 }, { ptr, i64 } { ptr @661, i64 16 }, { ptr, i64 } { ptr @662, i64 10 }, { ptr, i64 } { ptr @663, i64 21 }, { ptr, i64 } { ptr @664, i64 18 }, { ptr, i64 } { ptr @665, i64 17 }, { ptr, i64 } { ptr @666, i64 18 }, { ptr, i64 } { ptr @667, i64 10 }, { ptr, i64 } { ptr @668, i64 8 }, { ptr, i64 } { ptr @669, i64 12 }, { ptr, i64 } { ptr @670, i64 15 }, { ptr, i64 } { ptr @671, i64 13 }, { ptr, i64 } { ptr @672, i64 10 }, { ptr, i64 } { ptr @673, i64 16 }, { ptr, i64 } { ptr @674, i64 9 }, { ptr, i64 } { ptr @675, i64 10 }, { ptr, i64 } { ptr @676, i64 16 }, { ptr, i64 } { ptr @677, i64 26 }, { ptr, i64 } { ptr @678, i64 15 }, { ptr, i64 } { ptr @679, i64 17 }, { ptr, i64 } { ptr @680, i64 15 }, { ptr, i64 } { ptr @681, i64 23 }, { ptr, i64 } { ptr @682, i64 25 }, { ptr, i64 } { ptr @683, i64 24 }, { ptr, i64 } { ptr @684, i64 11 }, { ptr, i64 } { ptr @685, i64 16 }, { ptr, i64 } { ptr @686, i64 5 }, { ptr, i64 } { ptr @687, i64 16 }, { ptr, i64 } { ptr @688, i64 17 }, { ptr, i64 } { ptr @689, i64 12 }, { ptr, i64 } { ptr @690, i64 8 }, { ptr, i64 } { ptr @691, i64 8 }, { ptr, i64 } { ptr @692, i64 11 }, { ptr, i64 } { ptr @693, i64 11 }, { ptr, i64 } { ptr @694, i64 11 }, { ptr, i64 } { ptr @695, i64 11 }, { ptr, i64 } { ptr @696, i64 15 }, { ptr, i64 } { ptr @697, i64 21 }, { ptr, i64 } { ptr @698, i64 11 }, { ptr, i64 } { ptr @699, i64 22 }, { ptr, i64 } { ptr @700, i64 21 }, { ptr, i64 } { ptr @701, i64 10 }, { ptr, i64 } { ptr @702, i64 11 }, { ptr, i64 } { ptr @703, i64 6 }, { ptr, i64 } { ptr @704, i64 10 }, { ptr, i64 } { ptr @705, i64 21 }, { ptr, i64 } { ptr @706, i64 8 }, { ptr, i64 } { ptr @707, i64 12 }, { ptr, i64 } { ptr @708, i64 10 }, { ptr, i64 } { ptr @709, i64 7 }, { ptr, i64 } { ptr @710, i64 18 }, { ptr, i64 } { ptr @711, i64 11 }, { ptr, i64 } { ptr @712, i64 25 }, { ptr, i64 } { ptr @713, i64 25 }, { ptr, i64 } { ptr @714, i64 20 }, { ptr, i64 } { ptr @715, i64 15 }, { ptr, i64 } { ptr @716, i64 17 }, { ptr, i64 } { ptr @717, i64 16 }, { ptr, i64 } { ptr @718, i64 31 }, { ptr, i64 } { ptr @719, i64 8 }, { ptr, i64 } { ptr @720, i64 11 }, { ptr, i64 } { ptr @721, i64 13 }, { ptr, i64 } { ptr @722, i64 15 }, { ptr, i64 } { ptr @723, i64 23 }, { ptr, i64 } { ptr @724, i64 20 }, { ptr, i64 } { ptr @725, i64 15 }, { ptr, i64 } { ptr @726, i64 19 }, { ptr, i64 } { ptr @727, i64 23 }, { ptr, i64 } { ptr @728, i64 23 }, { ptr, i64 } { ptr @729, i64 9 }, { ptr, i64 } { ptr @730, i64 9 }, { ptr, i64 } { ptr @731, i64 15 }, { ptr, i64 } { ptr @732, i64 17 }, { ptr, i64 } { ptr @733, i64 13 }, { ptr, i64 } { ptr @734, i64 10 }, { ptr, i64 } { ptr @735, i64 13 }, { ptr, i64 } { ptr @736, i64 13 }, { ptr, i64 } { ptr @737, i64 17 }, { ptr, i64 } { ptr @738, i64 13 }, { ptr, i64 } { ptr @739, i64 17 }, { ptr, i64 } { ptr @740, i64 11 }, { ptr, i64 } { ptr @741, i64 12 }, { ptr, i64 } { ptr @742, i64 20 }, { ptr, i64 } { ptr @743, i64 16 }, { ptr, i64 } { ptr @744, i64 25 }, { ptr, i64 } { ptr @745, i64 25 }, { ptr, i64 } { ptr @746, i64 21 }, { ptr, i64 } { ptr @747, i64 21 }, { ptr, i64 } { ptr @748, i64 20 }, { ptr, i64 } { ptr @749, i64 12 }, { ptr, i64 } { ptr @750, i64 11 }, { ptr, i64 } { ptr @751, i64 16 }, { ptr, i64 } { ptr @752, i64 13 }, { ptr, i64 } { ptr @753, i64 21 }, { ptr, i64 } { ptr @754, i64 8 }, { ptr, i64 } { ptr @755, i64 17 }, { ptr, i64 } { ptr @756, i64 10 }, { ptr, i64 } { ptr @757, i64 10 }, { ptr, i64 } { ptr @758, i64 17 }, { ptr, i64 } { ptr @759, i64 14 }, { ptr, i64 } { ptr @760, i64 23 }, { ptr, i64 } { ptr @761, i64 13 }, { ptr, i64 } { ptr @762, i64 16 }, { ptr, i64 } { ptr @763, i64 14 }, { ptr, i64 } { ptr @764, i64 27 }, { ptr, i64 } { ptr @765, i64 19 }, { ptr, i64 } { ptr @766, i64 28 }, { ptr, i64 } { ptr @767, i64 27 }, { ptr, i64 } { ptr @768, i64 23 }, { ptr, i64 } { ptr @769, i64 27 }, { ptr, i64 } { ptr @770, i64 16 }, { ptr, i64 } { ptr @771, i64 17 }, { ptr, i64 } { ptr @772, i64 16 }, { ptr, i64 } { ptr @773, i64 23 }, { ptr, i64 } { ptr @774, i64 20 }, { ptr, i64 } { ptr @775, i64 17 }, { ptr, i64 } { ptr @776, i64 21 }, { ptr, i64 } { ptr @777, i64 14 }, { ptr, i64 } { ptr @778, i64 22 }, { ptr, i64 } { ptr @779, i64 17 }, { ptr, i64 } { ptr @780, i64 10 }, { ptr, i64 } { ptr @781, i64 20 }, { ptr, i64 } { ptr @782, i64 14 }, { ptr, i64 } { ptr @783, i64 24 }, { ptr, i64 } { ptr @784, i64 25 }, { ptr, i64 } { ptr @785, i64 16 }, { ptr, i64 } { ptr @786, i64 15 }, { ptr, i64 } { ptr @787, i64 21 }, { ptr, i64 } { ptr @788, i64 22 }, { ptr, i64 } { ptr @789, i64 31 }, { ptr, i64 } { ptr @790, i64 21 }, { ptr, i64 } { ptr @791, i64 20 }, { ptr, i64 } { ptr @792, i64 13 }, { ptr, i64 } { ptr @793, i64 18 }, { ptr, i64 } { ptr @794, i64 21 }, { ptr, i64 } { ptr @795, i64 11 }, { ptr, i64 } { ptr @796, i64 13 }, { ptr, i64 } { ptr @797, i64 13 }, { ptr, i64 } { ptr @798, i64 11 }, { ptr, i64 } { ptr @799, i64 7 }, { ptr, i64 } { ptr @800, i64 27 }, { ptr, i64 } { ptr @801, i64 14 }, { ptr, i64 } { ptr @802, i64 24 }, { ptr, i64 } { ptr @803, i64 13 }], align 8

; Function Attrs: nounwind uwtable
declare void @zig_add(ptr nonnull align 4, i64, i32)

; Function Attrs: nounwind uwtable
declare i32 @zig_sum(ptr nonnull readonly align 4, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64) #1

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr nonnull)

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare ptr @llvm.returnaddress(i32 immarg) #4

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @debug.defaultPanic(ptr nonnull, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.init(ptr noalias nonnull sret({ %debug.SelfInfo, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #5

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMap(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).init"(ptr noalias nonnull sret(%"hash_map.HashMap(usize,*debug.Dwarf.ElfModule,hash_map.AutoContext(usize),80)"), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.getSelfDebugInfo(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.getDebugInfoAllocator(ptr noalias nonnull sret(%mem.Allocator), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.open(ptr noalias nonnull sret({ %debug.SelfInfo, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: noinline nounwind uwtable
declare fastcc void @builtin.returnError(ptr nonnull)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).unwrapNull"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.abi.regValueNative(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.abi.regBytes(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8, ptr nonnull readonly align 1)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.bytesAsValue__anon_2215(ptr nonnull, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.UnwindContext.init(ptr noalias nonnull sret({ %debug.SelfInfo.UnwindContext, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.create__anon_2231(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.copyContext(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #7

; Function Attrs: nounwind uwtable
declare fastcc void @debug.StackIterator.initWithContext(ptr noalias nonnull sret({ %debug.StackIterator, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.StackIterator.init(ptr noalias nonnull sret(%debug.StackIterator), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.SelfInfo.lookupModuleDl__struct_2655.callback(ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).startGreaterThanEnd"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceTo__anon_2732(ptr nonnull, ptr readonly align 1)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).castToNull"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i1 @mem.eql__anon_2772(ptr nonnull, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.mapWholeFile(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.getEndPos(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.close(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_2887(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.mmap(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr align 4096, i64, i32, i32, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.readElfDebugInfo(ptr noalias nonnull sret({ %debug.Dwarf.ElfModule, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr readonly align 1, i64, ptr readonly align 1, i64, ptr nonnull readonly align 4, ptr nonnull align 8, ptr readonly align 4096, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.cwd(ptr noalias nonnull sret(%fs.Dir), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.Dir.openFile(ptr noalias nonnull sret({ %fs.File, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.openSelfExe(ptr noalias nonnull sret({ %fs.File, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.ElfModule.load(ptr noalias nonnull sret({ %debug.Dwarf.ElfModule, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 4096, i64, ptr readonly align 1, i64, ptr nonnull readonly align 4, ptr nonnull align 8, ptr readonly align 4096, i64, ptr readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.readEhPointer(ptr noalias nonnull sret({ { i64, i8, [7 x i8] }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8, i8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_3068(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_3071(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_3074(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readUleb128__anon_3080(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readIleb128__anon_3087(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_3090(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_3093(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_3094(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.bad(ptr nonnull)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @math.add__anon_3116(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr nonnull)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).incorrectAlignment"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.ExceptionFrameHeader.entrySize(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.EntryHeader.read(ptr noalias nonnull sret({ %debug.Dwarf.EntryHeader, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr align 4, i4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.assert(ptr nonnull, i1)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.readUnitHeader(ptr noalias nonnull sret({ %debug.Dwarf.UnitHeader, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readAddressChecked(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i1, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readAddress(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @__zig_is_named_enum_value_debug.Dwarf.Section.Id(i4)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).reachedUnreachable"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @math.sub__anon_3209(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.pcRelBase(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64) #1

; Function Attrs: nounwind uwtable
declare fastcc void @math.sub__anon_3251(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.add__anon_3252(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.CommonInformationEntry.parse(ptr noalias nonnull sret({ %debug.Dwarf.CommonInformationEntry, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, i64, i1, i1, i4, i64, i8, i1)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readUleb128__anon_3231(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readIleb128__anon_3232(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readUleb128__anon_3234(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readUleb128__anon_3239(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.FrameDescriptionEntry.parse(ptr noalias nonnull sret({ %debug.Dwarf.FrameDescriptionEntry, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, i64, i1, ptr nonnull readonly align 8, i8, i1)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.scanCieFdeInfo(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @debug.Dwarf.section(ptr nonnull, ptr nonnull readonly align 8, i4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.sectionVirtualOffset(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i4, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).put"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).get"(ptr noalias nonnull sret({ %debug.Dwarf.CommonInformationEntry, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.sortUnstable__anon_3297(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.scanAllUnwindInfo(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.lookupModuleDl(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.dl_iterate_phdr__anon_2777(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"hash_map.HashMap(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).get"(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.create__anon_2786(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.destroy__anon_3000(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"hash_map.HashMap(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).putNoClobber"(ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.getModuleForAddress(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.printLineFromFileAnyOs(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.read(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.indexOfScalar__anon_3421(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.replaceScalar__anon_3429(ptr nonnull, ptr nonnull align 1, i64, i8, i8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.writeAll(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.writeByte(ptr nonnull, ptr nonnull align 8, i8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.printLineInfo__anon_3339(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 1, i64, i2)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.tty.Config.setColor(ptr nonnull, i2, ptr nonnull align 8, i5)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_3366(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_3394(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.splatByteAll(ptr nonnull, ptr nonnull align 8, i8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.printUnknownSource(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64, i2)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @debug.SelfInfo.getModuleNameForAddress(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.DebugRangeIterator.init(ptr noalias nonnull sret({ %debug.Dwarf.DebugRangeIterator, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.bswap.i32(i32) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.bswap.i64(i64) #1

; Function Attrs: nounwind uwtable
declare fastcc i1 @"__zig_is_named_enum_value_@typeInfo(debug.Dwarf.FormValue).@\22union\22.tag_type.?"(i5)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.Die.getAttrAddr(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_3542(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.readDebugAddr(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i16 @llvm.bswap.i16(i16) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i8, i1 } @llvm.uadd.with.overflow.i8(i8, i8) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.DebugRangeIterator.next(ptr noalias nonnull sret({ { %debug.Dwarf.PcRange, i8, [7 x i8] }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_3581(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.findCompileUnit(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @debug.Dwarf.Die.getAttr(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.missing(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.CompileUnit.SrcLocCache.findSource(ptr noalias nonnull sret({ %debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).keys"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @sort.upperBound__anon_3653(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).values"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.path.joinSepMaybeZ__anon_3692(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i8, ptr nonnull readonly align 8, i64, i1)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.dupe__anon_3706(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.path.isSep(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alloc__anon_3714(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).copyLenMismatch"(ptr nonnull)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).memcpyAlias"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.path.join(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.getLineNumberInfo(ptr noalias nonnull sret({ %debug.SourceLocation, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.populateSrcLocCache(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.usub.with.overflow.i32(i32, i32) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.getSymbol(ptr noalias nonnull sret({ %debug.Symbol, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @debug.Dwarf.getSymbolName(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.Die.getAttrString(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, ptr readonly align 1, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.ElfModule.getSymbolAtAddress(ptr noalias nonnull sret({ %debug.Symbol, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.printSourceAtAddress(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64, i2)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_3727(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.writeCurrentStackTrace(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i2, ptr nonnull readonly align 8)

; Function Attrs: naked nosanitize_coverage nounwind skipprofile uwtable
declare i64 @os.linux.x86_64.getContextInternal()

; Function Attrs: nounwind uwtable
declare fastcc void @debug.StackIterator.next(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.printLastUnwindError(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8, i2)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.usub.sat.i64(i64, i64) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.StackIterator.deinit(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.dumpCurrentStackTraceToWriter(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_1824(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.stderr(ptr noalias nonnull sret(%fs.File), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i2 @Io.tty.detectConfig(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_3741(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.resetSegfaultHandler(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc ptr @debug.lockStderrWriter(ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i32 @Thread.getCurrentId(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_1110(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 4)

; Function Attrs: cold noreturn nounwind null_pointer_is_valid uwtable
declare fastcc void @posix.abort(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_1120(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.dumpStackTrace(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.unlockStderrWriter(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.waitForOtherThreadToFinishPanicking(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i16 @fs.File.writeAll(ptr nonnull, ptr nonnull readonly align 4, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.sigemptyset(ptr noalias nonnull sret([1 x i64]), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.updateSegfaultHandler(ptr nonnull, ptr readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @Progress.lockStderrWriter(ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i32 @Thread.LinuxThreadImpl.getCurrentId(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_4085(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.raise(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @os.linux.sigfillset(ptr noalias nonnull sret([1 x i64]), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.sigprocmask(ptr nonnull, i32, ptr noalias readonly align 8, ptr noalias align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.sigaction(ptr nonnull, i8, ptr noalias readonly align 8, ptr noalias align 8)

; Function Attrs: nounwind uwtable
declare fastcc i32 @os.linux.gettid(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.tkill(ptr nonnull, i32, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.sigaddset(ptr nonnull, ptr nonnull align 8, i8)

; Function Attrs: noreturn nounwind uwtable
declare fastcc void @posix.exit(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_4207(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.writeStackTrace(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, ptr nonnull align 8, i2)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #1

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).divideByZero"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_4232(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @heap.arena_allocator.ArenaAllocator.init(ptr noalias nonnull sret(%heap.arena_allocator.ArenaAllocator), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @heap.arena_allocator.ArenaAllocator.allocator(ptr noalias nonnull sret(%mem.Allocator), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_4414(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i2 @Io.tty.Config.detect(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap() #12

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare ptr @llvm.frameaddress.p0(i32 immarg) #4

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_5058(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i8, i1 } @llvm.usub.with.overflow.i8(i8, i8) #1

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_5074(ptr nonnull, ptr nonnull align 8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @debug.panicExtra__anon_5090(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocBytesWithAlignment__anon_5129(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.relocateContext(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.StackIterator.next_internal(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.printUnwindError(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64, i16, i2)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_5163(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_5172(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.StackIterator.getLastError(ptr noalias nonnull sret({ %debug.StackIterator.getLastError__struct_5143, i8, [7 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @debug.panicExtra__anon_5180(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceTo__anon_5184(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_5209(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @mem.eqlBytes(ptr nonnull, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @process.getBaseAddress(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @dynamic_library.linkmap_iterator(ptr noalias nonnull sret({ %dynamic_library.LinkMap.Iterator, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).unwrapError"(ptr nonnull, i16)

; Function Attrs: nounwind uwtable
declare fastcc i1 @dynamic_library.LinkMap.Iterator.end(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @dynamic_library.LinkMap.Iterator.next(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).getContext"(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.toPosixPath(ptr noalias nonnull sret({ i16, [4096 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.Dir.openFileZ(ptr noalias nonnull sret({ %fs.File, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull readonly align 1, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.openFileAbsoluteZ(ptr noalias nonnull sret({ %fs.File, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 1, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.stat(ptr noalias nonnull sret({ %fs.File.Stat, i16, [14 x i8] }), ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.close(ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.mmap(ptr nonnull, ptr align 1, i64, i64, i32, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.errno__anon_5638(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.unexpectedErrno(ptr nonnull, i16)

; Function Attrs: nounwind uwtable
declare fastcc i32 @"hash.crc.impl.Crc(u32, .{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 }).hash"(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceTo__anon_5769(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.chopSlice(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.alignForward__anon_5782(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.fixed(ptr noalias nonnull sret(%Io.Reader), ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeStructPointer__anon_5961(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.byteSwapAllFields__anon_5970(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.init(ptr noalias nonnull sret(%compress.flate.Decompress), ptr nonnull, ptr nonnull align 8, i2, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Reader.appendRemainingUnlimited(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.invalidDebugInfoDetected(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(u8, null).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(u8, null).toOwnedSlice"(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @posix.getenv(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.openDirAbsolute(ptr noalias nonnull sret({ %fs.Dir, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_6088(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fmt.allocPrint__anon_6110(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.Dir.close(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.ElfModule.loadPath(ptr noalias nonnull sret({ %debug.Dwarf.ElfModule, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8, ptr readonly align 1, i64, ptr nonnull readonly align 4, ptr nonnull align 8, ptr readonly align 4096, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fmt.bufPrint__anon_6161(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 1, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fmt.bufPrint__anon_6167(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 1, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Build.Cache.Directory.cwd(ptr noalias nonnull sret(%Build.Cache.Directory), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.selfExeDirPath(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.realpath(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.open(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i6 @mem.Alignment.fromByteUnits(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_6246(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i6, i1 } @llvm.umul.with.overflow.i6(i6, i6) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i6, i1 } @llvm.uadd.with.overflow.i6(i6, i6) #1

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readIleb128__anon_6262(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i16, i1 } @llvm.usub.with.overflow.i16(i16, i16) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readIntChecked__anon_6311(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readIntChecked__anon_6321(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i64 @debug.Dwarf.Section.virtualOffset(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_6338(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i5, i1 } @llvm.umul.with.overflow.i5(i5, i5) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i5, i1 } @llvm.uadd.with.overflow.i5(i5, i5) #1

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readIleb128__anon_6351(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_6360(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i3, i1 } @llvm.umul.with.overflow.i3(i3, i3) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i3, i1 } @llvm.uadd.with.overflow.i3(i3, i3) #1

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_6373(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).putContext"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getContext"(ptr noalias nonnull sret({ %debug.Dwarf.CommonInformationEntry, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.pdq__anon_6410(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).putNoClobberContext"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @debug.SelfInfo.lookupModuleNameDl(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_6621(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.write(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_6683(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.read(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.indexOfScalarPos__anon_6729(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, i64, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.unimplementedSendFile(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.defaultFlush(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.defaultRebase(ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg) #5

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.defaultDiscard(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Discarding.init(ptr noalias nonnull sret(%Io.Writer.Discarding), ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.stream(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.defaultReadVec(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.fixedDrain(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Limit.limited(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Reader.defaultRebase(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.splatByte(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.getStringGeneric(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr readonly align 1, i64, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).sentinelMismatch__anon_6827"(ptr nonnull, i8, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.getString(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.getLineString(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.FormValue.getUInt__anon_6861(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_6867(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_6869(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.Die.getAttrSecOffset(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.FormValue.getString(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.FormValue.getUInt__anon_6949(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_6954(ptr noalias nonnull sret({ i32, i8, [3 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_6956(ptr noalias nonnull sret({ i32, i8, [3 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.LineNumberProgram.addRow(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_7004(ptr noalias nonnull sret({ i32, i8, [3 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).put"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.runLineNumberProgram(ptr noalias nonnull sret({ %debug.Dwarf.CompileUnit.SrcLocCache, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.FixedBufferReader.seekTo(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readByteSigned(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readBytes(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FileEntry, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.FileEntry, null).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readBytesTo__anon_6914(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readUleb128__anon_6922(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.FileEntry, null).addManyAsSlice"(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.parseFormValue(ptr noalias nonnull sret({ %debug.Dwarf.FormValue, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FileEntry, null).ensureUnusedCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.LineNumberProgram.init(ptr noalias nonnull sret(%debug.Dwarf.LineNumberProgram), ptr nonnull, i1, i16)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.LineNumberProgram.reset(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.FixedBufferReader.seekForward(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #1

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).sortContextInternal__anon_7030"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.FileEntry, null).toOwnedSlice"(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).items__anon_7150"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @sort.partitionPoint__anon_7158(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).items__anon_7166"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_7185(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.MemoryAccessor.deinit(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.UnwindContext.deinit(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Progress.unlockStderrWriter(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @"atomic.Value(u32).init"(ptr noalias nonnull sret(%"atomic.Value(u32)"), ptr nonnull, i32)

; Function Attrs: cold nounwind uwtable
declare fastcc void @Thread.Futex.wait(ptr nonnull, ptr nonnull readonly align 4, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.write(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @os.linux.sigemptyset(ptr noalias nonnull sret([1 x i64]), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @Thread.Mutex.Recursive.lock(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Progress.clearWrittenWithEscapeCodes(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.flush(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_7443(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printIntAny__anon_7449(ptr nonnull, ptr nonnull align 8, i64, i8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printIntAny__anon_7451(ptr nonnull, ptr nonnull align 8, i32, i8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.sigprocmask(ptr nonnull, i32, ptr noalias readonly align 8, ptr noalias align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.sigaction(ptr nonnull, i8, ptr noalias readonly align 8, ptr noalias align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.x86_64.syscall0(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.x86_64.syscall2(ptr nonnull, i64, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @os.linux.sigaddset(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @os.linux.exit_group(ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.alignBufferOptions(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_7523(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @heap.arena_allocator.ArenaAllocator.State.promote(ptr noalias nonnull sret(%heap.arena_allocator.ArenaAllocator), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @heap.arena_allocator.ArenaAllocator.alloc(ptr nonnull, ptr nonnull align 1, i64, i6, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @heap.arena_allocator.ArenaAllocator.resize(ptr nonnull, ptr nonnull align 1, ptr nonnull align 1, i64, i6, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @heap.arena_allocator.ArenaAllocator.remap(ptr nonnull, ptr nonnull align 1, ptr nonnull align 1, i64, i6, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @heap.arena_allocator.ArenaAllocator.free(ptr nonnull, ptr nonnull align 1, ptr nonnull align 1, i64, i6, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @process.hasNonEmptyEnvVarConstant__anon_7604(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i1 @process.hasNonEmptyEnvVarConstant__anon_7610(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.File.getOrEnableAnsiEscapeSupport(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.fixed(ptr noalias nonnull sret(%Io.Writer), ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_7634(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @Io.Writer.buffered(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.ElfModule.getDwarfInfoForAddress(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.ExceptionFrameHeader.findEntry(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 4, ptr nonnull readonly align 8, i64, i64, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.Dwarf.ExceptionFrameHeader.isValidPtr__anon_7701(ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4, ptr nonnull readonly align 8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).inactiveUnionField__anon_7686"(ptr nonnull, i2, i2)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_7880(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"Io.GenericReader(*Io.fixed_buffer_stream.FixedBufferStream([]const u8), error{}, (function 'read')).typeErasedReadFn"(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 1, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.readByte(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).invalidErrorCode"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_7966(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_7985(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.call_frame.readBlock(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"Io.fixed_buffer_stream.FixedBufferStream([]const u8).reader"(ptr noalias nonnull sret(%"Io.GenericReader(*Io.fixed_buffer_stream.FixedBufferStream([]const u8),error{},(function 'read'))"), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readIleb128__anon_7996(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.call_frame.Instruction.read(ptr noalias nonnull sret({ %debug.Dwarf.call_frame.Instruction, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8, i1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @__zig_is_named_enum_value_debug.Dwarf.call_frame.Opcode(i8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).invalidEnumValue"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.readBytesNoEof__anon_7949(ptr noalias nonnull sret({ i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.readBytesNoEof__anon_7955(ptr noalias nonnull sret({ i16, [4 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.readBytesNoEof__anon_7960(ptr noalias nonnull sret({ i16, [8 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.SelfInfo.VirtualMachine.resolveCopyOnWrite(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).ensureUnusedCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @debug.SelfInfo.VirtualMachine.rowColumns(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).appendSliceAssumeCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.VirtualMachine.getOrAddColumn(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.VirtualMachine.step(ptr noalias nonnull sret({ %debug.SelfInfo.VirtualMachine.Row, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).pop"(ptr noalias nonnull sret({ %debug.SelfInfo.VirtualMachine.ColumnRange, i8, [7 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).shrinkRetainingCapacity"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.VirtualMachine.runTo(ptr noalias nonnull sret({ %debug.SelfInfo.VirtualMachine.Row, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 8, ptr nonnull readonly align 8, i8, i1)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.fixed_buffer_stream.fixedBufferStream__anon_7767(ptr noalias nonnull sret(%"Io.fixed_buffer_stream.FixedBufferStream([]const u8)"), ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.VirtualMachine.runToNative(ptr noalias nonnull sret({ %debug.SelfInfo.VirtualMachine.Row, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.applyOffset(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.SelfInfo.getRegDefaultValue(ptr nonnull, i8, ptr nonnull align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.SelfInfo.VirtualMachine.Column.resolveValue(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull align 4, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.MemoryAccessor.load__anon_8123(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).reset"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).run"(ptr noalias nonnull sret({ { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value", i8, [7 x i8] }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).inactiveUnionField__anon_8114"(ptr nonnull, i2, i2)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.unwindFrameDwarf(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, ptr nonnull align 8, ptr nonnull align 4, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.binarySearch__anon_7717(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.VirtualMachine.reset(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"__zig_is_named_enum_value_@typeInfo(debug.SelfInfo.VirtualMachine.RegisterRule).@\22union\22.tag_type.?"(i4)

; Function Attrs: nounwind uwtable
declare fastcc void @heap.arena_allocator.ArenaAllocator.deinit(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.create__anon_8139(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i8 @debug.SelfInfo.spRegNum(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.Dwarf.CommonInformationEntry.isSignalFrame(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.StackIterator.next_unwind(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.UnwindContext.getFp(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i8 @debug.SelfInfo.fpRegNum(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @mem.isAligned(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_8408(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i16, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_8445(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.lenSliceTo__anon_8452(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i1 @llvm.vector.reduce.or.v16i1(<16 x i1>) #1

; Function Attrs: nounwind uwtable
declare i64 @getauxval(i64) #8

; Function Attrs: nounwind uwtable
declare fastcc ptr @dynamic_library.get_DYNAMIC(ptr nonnull)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @debug.panicExtra__anon_8602(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).getAdapted__anon_8609"(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.openatZ(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, i32, ptr nonnull readonly align 1, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.flock(ptr nonnull, i32, i32)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.path.isAbsoluteZ(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.zeroes__anon_8712(ptr noalias nonnull sret(%os.linux.Statx), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.statx(ptr nonnull, i32, ptr nonnull readonly align 1, i32, i32, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @os.linux.errnoFromSyscall(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.Stat.fromLinux(ptr noalias nonnull sret(%fs.File.Stat), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.close(ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.x86_64.syscall6(ptr nonnull, i64, i64, i64, i64, i64, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.print__anon_8782(ptr nonnull, ptr nonnull readonly align 2)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.dumpCurrentStackTrace(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash.crc.impl.Crc(u32, .{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 }).init"(ptr noalias nonnull sret(%"hash.crc.impl.Crc(u32,.{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 })"), ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash.crc.impl.Crc(u32, .{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 }).update"(ptr nonnull, ptr nonnull align 4, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i32 @"hash.crc.impl.Crc(u32, .{ .polynomial = 79764919, .initial = 4294967295, .reflect_input = true, .reflect_output = true, .xor_output = 4294967295 }).final"(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.lenSliceTo__anon_8815(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @mem.isValidAlignGeneric__anon_8822(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.alignBackward__anon_8825(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.endingStream(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.endingDiscard(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.endingReadVec(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Reader.endingRebase(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeArray__anon_8842(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Container.Metadata.init(ptr noalias nonnull sret(%compress.flate.Container.Metadata), ptr nonnull, i2)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.initOwnedSlice(ptr noalias nonnull sret(%Io.Writer.Allocating), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.streamRemaining(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(u8, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_8961(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_8966(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(u8, null).clearAndFree"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceTo__anon_8986(ptr nonnull, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.path.isAbsolute(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.Dir.openDir(ptr noalias nonnull sret({ %fs.Dir, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_9003(ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.initCapacity(ptr noalias nonnull sret({ %Io.Writer.Allocating, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_9010(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.deinit(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.toOwnedSlice(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.munmap(ptr nonnull, ptr nonnull readonly align 4096, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_10124(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_10127(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.selfExePath(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @fs.path.dirname(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.realpathZ(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 1, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.scanAllFunctions(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.Dwarf.scanAllCompileUnits(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @math.isPowerOfTwo__anon_10160(ptr nonnull, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.cttz.i64(i64, i1 immarg) #1

; Function Attrs: nounwind uwtable
declare fastcc void @debug.MemoryAccessor.load__anon_10177(ptr noalias nonnull sret({ i32, i8, [3 x i8] }), ptr nonnull, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.MemoryAccessor.load__anon_10182(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getOrPutContext"(ptr noalias nonnull sret({ %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult", i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getAdapted__anon_10209"(ptr noalias nonnull sret({ %debug.Dwarf.CommonInformationEntry, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.pdqContext__anon_10225(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SafetyLock.lock(ptr nonnull, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).growIfNeeded"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SafetyLock.unlock(ptr nonnull, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).putAssumeCapacityNoClobberContext"(ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @debug.SelfInfo.lookupModuleNameDl__struct_10246.callback(ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.dl_iterate_phdr__anon_10259(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @fs.path.basename(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printIntAny__anon_10264(ptr nonnull, ptr nonnull align 8, i64, i8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.read(ptr nonnull, i32, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @valgrind.runningOnValgrind(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i1 @math.isPowerOfTwo__anon_10325(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @simd.firstTrue__anon_10343(ptr noalias nonnull sret({ i4, i8 }), ptr nonnull, <16 x i1>)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i1 @llvm.vector.reduce.or.v8i1(<8 x i1>) #1

; Function Attrs: nounwind uwtable
declare fastcc void @simd.firstTrue__anon_10355(ptr noalias nonnull sret({ i3, i8 }), ptr nonnull, <8 x i1>)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Discarding.drain(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Discarding.sendFile(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @Io.Limit.slice(ptr nonnull, i64, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.writeSplat(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @debug.panicExtra__anon_10389(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.FileEntry, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.Dwarf.FileEntry, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_10417(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @leb128.readUleb128__anon_10425(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i4, i1 } @llvm.umul.with.overflow.i4(i4, i4) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i4, i1 } @llvm.uadd.with.overflow.i4(i4, i4) #1

; Function Attrs: nounwind uwtable
declare fastcc void @array_list.addOrOom(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FileEntry, null).resize"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_10509(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.FixedBufferReader.readInt__anon_10512(ptr noalias nonnull sret({ i24, i16, [2 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FileEntry, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SafetyLock.assertUnlocked(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @array_hash_map.IndexHeader.free(ptr nonnull, ptr nonnull align 4, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).putContext"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).sortUnstable__anon_10556"(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @array_hash_map.IndexHeader.reset(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeader"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_10569(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_10571(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.FileEntry, null).clearAndFree"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).slice"(ptr noalias nonnull sret(%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).Slice"), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).Slice.items__anon_10591"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @sort.upperBound__anon_3653.S.predicate(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).Slice.items__anon_10593"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.mul__anon_10597(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocBytesWithAlignment__anon_10599(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.SelfInfo.VirtualMachine.deinit(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.destroy__anon_10613(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Thread.Mutex.Recursive.unlock(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Thread.Futex.LinuxImpl.wait(ptr nonnull, ptr nonnull readonly align 4, i32, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.write(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Thread.Mutex.lock(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Progress.write(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fmt.digits2(ptr noalias nonnull sret([2 x i8]), ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc i8 @fmt.digitToChar(ptr nonnull, i8, i1)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.x86_64.syscall4(ptr nonnull, i64, i64, i64, i64, i64)

; Function Attrs: naked noreturn nosanitize_coverage nounwind skipprofile uwtable
declare void @os.linux.x86_64.restore_rt()

; Function Attrs: nounwind uwtable
declare fastcc void @os.linux.sigset_bit_index(ptr noalias nonnull sret(%os.linux.sigset_bit_index__struct_10745), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.x86_64.syscall1(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.alignBuffer(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1, i64, i64, i2, i8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.Alignment.toByteUnits(ptr nonnull, i6)

; Function Attrs: nounwind uwtable
declare fastcc ptr @heap.arena_allocator.ArenaAllocator.createNode(ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.File.supportsAnsiEscapeCodes(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.noopFlush(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.failingRebase(ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"__zig_is_named_enum_value_@typeInfo(debug.Dwarf.EntryHeader__union_3155).@\22union\22.tag_type.?"(i2)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"__zig_tag_name_@typeInfo(debug.Dwarf.EntryHeader__union_3155).@\22union\22.tag_type.?"(i2)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @debug.panicExtra__anon_10881(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.MemoryAccessor.load__anon_10883(ptr noalias nonnull sret({ i8, i8 }), ptr nonnull, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc i2 @debug.SelfInfo.unwindFrameDwarf__struct_7712.compareFn(ptr nonnull, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).clearRetainingCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).clearRetainingCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"Io.fixed_buffer_stream.FixedBufferStream([]const u8).read"(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.read(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.DeprecatedReader.readNoEof(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).clearRetainingCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).step"(ptr noalias nonnull sret({ i16, i1, [1 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"__zig_is_named_enum_value_@typeInfo(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value).@\22union\22.tag_type.?"(i2)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"__zig_tag_name_@typeInfo(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value).@\22union\22.tag_type.?"(i2)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.MemoryAccessor.read(ptr nonnull, ptr nonnull align 4, i64, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i8 @debug.Dwarf.abi.spRegNum(ptr nonnull, i6, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i8 @debug.Dwarf.abi.fpRegNum(ptr nonnull, i6, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @mem.isAlignedGeneric__anon_11009(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.optionsForbidden(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printErrorSet(ptr nonnull, ptr nonnull align 8, i16)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.indexOfSentinel__anon_11458(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_11474(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).getIndex__anon_11480"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).values"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.openat(ptr nonnull, i32, ptr nonnull readonly align 1, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.flock(ptr nonnull, i32, i32)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.path.isAbsolutePosixZ(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_11655(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.x86_64.syscall5(ptr nonnull, i64, i64, i64, i64, i64, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i128, i1 } @llvm.smul.with.overflow.i128(i128, i128) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i128, i1 } @llvm.sadd.with.overflow.i128(i128, i128) #1

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_11712(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 2)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.take(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_13799(ptr nonnull, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.lenSliceTo__anon_13803(ptr nonnull, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.path.isAbsolutePosix(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.Dir.openDirZ(ptr noalias nonnull sret({ %fs.Dir, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull readonly align 1, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_13827(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.toArrayList(ptr noalias nonnull sret(%"array_list.Aligned(u8,null)"), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.setArrayList(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.munmap(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_13904(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.readlinkZ(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 1, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @fs.path.dirnamePosix(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.openZ(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @os.getFdPath(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, i32, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.parseAbbrevTable(ptr noalias nonnull sret({ %debug.Dwarf.Abbrev.Table, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).init"(ptr noalias nonnull sret(%"array_list.AlignedManaged(debug.Dwarf.Abbrev,null)"), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).init"(ptr noalias nonnull sret(%"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr,null)"), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).deinit"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.Abbrev.deinit(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).deinit"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).toOwnedSlice"(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).toOwnedSlice"(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.getAbbrevTable(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.Abbrev.Table, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.FormValue.getUInt__anon_14143(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_14148(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.Die.getAttrRef(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #1

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_14105(ptr noalias nonnull sret({ i7, i8 }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alloc__anon_14113(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.indexOfNonePos__anon_14124(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, i64, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.Dwarf.parseDie(ptr noalias nonnull sret({ { %debug.Dwarf.Die, i8, [7 x i8] }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64, ptr nonnull readonly align 8, i1)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_14132(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.Func, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Die.Attr, null).init"(ptr noalias nonnull sret(%"array_list.AlignedManaged(debug.Dwarf.Die.Attr,null)"), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Die.Attr, null).deinit"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Die.Attr, null).resize"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.dupe__anon_14198(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.CompileUnit, null).append"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_14211(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_14218(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getOrPutContextAdapted__anon_14224"(ptr noalias nonnull sret({ %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult", i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getIndexAdapted__anon_14231"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).values"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @math.floorPowerOfTwo__anon_14252(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.insertionContext__anon_14267(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.heapContext__anon_14270(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: cold nounwind uwtable
declare fastcc void @sort.pdq.breakPatterns__anon_14273(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i2 @sort.pdq.chosePivot__anon_14281(ptr nonnull, i64, i64, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.reverseRange__anon_14287(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: cold nounwind uwtable
declare fastcc i1 @sort.pdq.partialInsertionSort__anon_14295(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @sort.pdq.pdq__anon_6410.Context.lessThan(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @sort.pdq.partitionEqual__anon_14305(ptr nonnull, i64, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @sort.pdq.partition__anon_14311(ptr nonnull, i64, i64, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i32 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).load"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32) #1

; Function Attrs: nounwind uwtable
declare fastcc i32 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).capacityForSize"(ptr nonnull, i32)

; Function Attrs: cold nounwind uwtable
declare fastcc i16 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).grow"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i32)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).containsContext"(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @hash_map.getAutoHashFn__struct_14348.hash(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i32 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).capacity"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).Metadata.isUsed"(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc i7 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).Metadata.takeFingerprint"(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).Metadata.fill"(ptr nonnull, ptr nonnull align 1, i7)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).keys"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @fs.path.basenamePosix(ptr nonnull, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.x86_64.syscall3(ptr nonnull, i64, i64, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @valgrind.doClientRequestExpr(ptr nonnull, i64, i32, i64, i64, i64, i64, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i4 @llvm.vector.reduce.umin.v16i4(<16 x i4>) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i3 @llvm.vector.reduce.umin.v8i3(<8 x i3>) #1

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.Reader.getSize(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Limit.minInt64(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @fs.File.Reader.seekBy(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Limit.minInt(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Writer.countSplat(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_14552(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.Dwarf.FileEntry, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_14568(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.FileEntry, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.FileEntry, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).allocatedBytes"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_14593(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @array_hash_map.capacityIndexSize(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @array_hash_map.IndexHeader.length(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_14609(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getOrPutContext"(ptr noalias nonnull sret({ %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult", i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).sortInternal__anon_14622"(ptr nonnull, ptr nonnull readonly align 8, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i2 @array_hash_map.IndexHeader.capacityIndexType(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeaderGeneric__anon_14639"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeaderGeneric__anon_14640"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeaderGeneric__anon_14641"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_14648(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_14650(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i2 @debug.Dwarf.CompileUnit.SrcLocCache.findSource__struct_3648.order(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i2 @math.Order.invert(ptr nonnull, i2)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Thread.Mutex.unlock(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.futex_4arg(ptr nonnull, ptr nonnull readonly align 1, i32, i32, ptr readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.write(ptr nonnull, i32, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Thread.Mutex.FutexImpl.lock(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @SinglyLinkedList.prepend(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @fs.File.isTty(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @posix.getenvZ(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_14935(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_14943(ptr nonnull, ptr nonnull align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.readAll(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).readOperand"(ptr noalias nonnull sret({ { %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand", i8, [7 x i8] }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15051"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15053"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.readByteSigned(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15065"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15069"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i16)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15073"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15077"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15094"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).generic__anon_15097"(ptr noalias nonnull sret(%"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand"), ptr nonnull, i16)

; Function Attrs: nounwind uwtable
declare fastcc void @"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value.asIntegral"(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.divTrunc__anon_15189(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.negate__anon_15208(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.sub__anon_15214(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.Dwarf.expression.isOpcodeValidInCFA(ptr nonnull, i8)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).inactiveUnionField__anon_15138"(ptr nonnull, i4, i4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).pop"(ptr noalias nonnull sret({ %"debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value", i8, [7 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.swap__anon_15161(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.abs.i64(i64, i1 immarg) #1

; Function Attrs: nounwind uwtable
declare fastcc void @math.add__anon_15215(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @math.shl__anon_15219(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @math.shr__anon_15222(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @math.shr__anon_15224(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.Dwarf.expression.isOpcodeRegisterLocation(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @debug.MemoryAccessor.load__anon_15237(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.add__anon_15241(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_15243(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i32 @os.linux.getpid(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.process_vm_readv(ptr nonnull, i32, ptr nonnull readonly align 8, i64, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fmt.bufPrint__anon_15445(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 1, i64, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.openFileAbsolute(ptr noalias nonnull sret({ %fs.File, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 1, i64, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.pread(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.MemoryAccessor.isValidMemory(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @__zig_is_named_enum_value_Target.Cpu.Arch(i6)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.alignBackward__anon_15465(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.writeVecAll(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).exactDivisionRemainder"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).Metadata.isFree"(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @hash_map.getAutoEqlFn__struct_15525.eql(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).header"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_15602(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i16, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.peek(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.toss(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.Dir.openDirFlagsZ(ptr noalias nonnull sret({ %fs.Dir, i16, [2 x i8] }), ptr nonnull, ptr nonnull readonly align 4, ptr nonnull readonly align 1, i32)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printHex(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1, i64, i1)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.readlink(ptr nonnull, ptr noalias nonnull readonly align 1, ptr noalias nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.open(ptr nonnull, ptr nonnull readonly align 1, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fmt.bufPrintZ__anon_15682(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 1, i64, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_15705(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_15714(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_15726(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_15728(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).clearAndFree"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_15744(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_15746(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).clearAndFree"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.Abbrev.Table, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_15767(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @debug.Dwarf.Abbrev.Table.get(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).forLenMismatch"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_15788(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.Func, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.AlignedManaged(debug.Dwarf.Die.Attr, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Die.Attr, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(debug.Dwarf.CompileUnit, null).addOne"(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).ensureTotalCapacityContext"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).slice"(ptr noalias nonnull sret(%"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).Slice"), ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).Slice.items__anon_15863"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).Slice.items__anon_15868"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getOrPutAssumeCapacityAdapted__anon_15876"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).Slice.items__anon_15890"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).checkedEql__anon_15896"(ptr nonnull, i64, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getIndexWithHeaderGeneric__anon_15902"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getIndexWithHeaderGeneric__anon_15903"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getIndexWithHeaderGeneric__anon_15904"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).items__anon_15910"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.uadd.sat.i64(i64, i64) #1

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.Dwarf.FrameDescriptionEntry, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_15927(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_15931(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_15934(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i6 @math.log2_int__anon_15936(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.pdq__anon_6410.Context.swap(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.siftDown__anon_15946(ptr nonnull, i64, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @math.ceilPowerOfTwoAssert__anon_15950(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.sort3__anon_15957(ptr nonnull, i64, i64, i64, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.Dwarf.scanCieFdeInfo__struct_3292.lessThan(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.ceilPowerOfTwo__anon_15962(ptr noalias nonnull sret({ i32, i16, [2 x i8] }), ptr nonnull, i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #1

; Function Attrs: nounwind uwtable
declare fastcc i1 @math.isPowerOfTwo__anon_15965(ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).allocate"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).initMetadatas"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.swap__anon_15978(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).deinit"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).containsAdapted__anon_15987"(ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_16006(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @hash.wyhash.Wyhash.hash(ptr nonnull, i64, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @valgrind.doClientRequest(ptr nonnull, i64, i64, i64, i64, i64, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i3 @fs.File.Reader.Mode.toStreaming(ptr nonnull, i3)

; Function Attrs: nounwind uwtable
declare fastcc i64 @fs.File.Reader.logicalPos(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.Reader.setLogicalPos(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.lseek_CUR(ptr nonnull, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Limit.limited64(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.Reader.discard(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_16132(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).capacityInBytes"(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_16181(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i2 @array_hash_map.capacityIndexType(ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_16207(ptr nonnull, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getOrPutContextAdapted__anon_16213"(ptr noalias nonnull sret({ %"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult", i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.sortUnstableContext__anon_16221(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @array_hash_map.IndexHeader.indexes__anon_16229(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i32 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).checkedHash__anon_16237"(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @array_hash_map.safeTruncate__anon_16241(ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i64 @array_hash_map.IndexHeader.constrainIndex(ptr nonnull, ptr nonnull readonly align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"array_hash_map.Index(u8).isEmpty"(ptr nonnull, ptr nonnull readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @array_hash_map.IndexHeader.indexes__anon_16256(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"array_hash_map.Index(u16).isEmpty"(ptr nonnull, ptr nonnull readonly align 2)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i16, i1 } @llvm.uadd.with.overflow.i16(i16, i16) #1

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @array_hash_map.IndexHeader.indexes__anon_16269(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"array_hash_map.Index(u32).isEmpty"(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc i2 @math.order__anon_16286(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_16292(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.SelfInfo.VirtualMachine.Column, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_16299(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_16306(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Thread.Mutex.FutexImpl.unlock(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i1 @Thread.Mutex.FutexImpl.tryLock(ptr nonnull, ptr nonnull align 4)

; Function Attrs: cold nounwind uwtable
declare fastcc void @Thread.Mutex.FutexImpl.lockSlow(ptr nonnull, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i1 @posix.isatty(ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.DeprecatedReader.readAtLeast(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_16454(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_16458(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.SelfInfo.VirtualMachine.ColumnRange, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"__zig_is_named_enum_value_@typeInfo(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand).@\22union\22.tag_type.?"(i4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"__zig_tag_name_@typeInfo(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Operand).@\22union\22.tag_type.?"(i4)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_16497(ptr nonnull, ptr nonnull align 2)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_16513(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.pread(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, ptr nonnull align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.msync(ptr nonnull, ptr nonnull align 4096, i64, i32)

; Function Attrs: nounwind uwtable
declare fastcc i1 @mem.isValidAlignGeneric__anon_16545(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.writeVec(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @meta.eql__anon_16565(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_16568(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i16)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printIntAny__anon_16570(ptr nonnull, ptr nonnull align 8, i16, i8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Reader.fill(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fmt.bufPrint__anon_16611(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 1, i64, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_16617(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_16626(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_16642(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_16644(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_16660(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_16662(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.Abbrev.Table, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.Dwarf.Abbrev.Table, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.Func, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.Dwarf.Func, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.Die.Attr, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Die.Attr, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.CompileUnit, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @"array_list.Aligned(debug.Dwarf.CompileUnit, null).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i32 @array_hash_map.IndexHeader.capacity(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @array_hash_map.IndexHeader.findBitIndex(ptr noalias nonnull sret({ i16, i8, [1 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @array_hash_map.IndexHeader.alloc(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeader"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getOrPutInternal__anon_16762"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 4)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getOrPutInternal__anon_16763"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 4)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getOrPutInternal__anon_16764"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i1 @array_hash_map.getAutoEqlFn__struct_16778.eql(ptr nonnull, i64, i64, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getSlotByKey__anon_16788"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4, ptr nonnull align 1, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getSlotByKey__anon_16790"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4, ptr nonnull align 2, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).getSlotByKey__anon_16792"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_16801(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_16805(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_16807(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.ctlz.i64(i64, i1 immarg) #1

; Function Attrs: nounwind uwtable
declare fastcc void @mem.swap__anon_16813(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @math.ceilPowerOfTwo__anon_16816(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i33 @math.ceilPowerOfTwoPromote__anon_16824(ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.Alignment.forward(ptr nonnull, i6, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_16834(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).deallocate"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @hash.wyhash.Wyhash.init(ptr noalias nonnull sret(%hash.wyhash.Wyhash), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Reader.bufferedLen(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.lseek(ptr nonnull, i32, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.readv(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @fs.File.seekBy(ptr nonnull, ptr nonnull readonly align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_16961(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printIntAny__anon_16963(ptr nonnull, ptr nonnull align 8, i8, i8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).ensureTotalCapacityContext"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getIndexAdapted__anon_16982"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getOrPutAssumeCapacityAdapted__anon_16990"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.pdqContext__anon_16993(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i32 @array_hash_map.getAutoHashFn__struct_16998.hash(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i32 @array_hash_map.IndexHeader.mask(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_17021(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_17028(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_17039(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc void @Thread.Futex.wake(ptr nonnull, ptr nonnull readonly align 4, i32)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_17085(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_17090(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_17094(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true }).Value, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printValue__anon_17114(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.pread(ptr nonnull, i32, ptr nonnull align 1, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.msync(ptr nonnull, ptr nonnull readonly align 1, i64, i32)

; Function Attrs: nounwind uwtable
declare fastcc i1 @math.isPowerOfTwo__anon_17139(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Reader.fillUnbuffered(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.print__anon_17150(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.Abbrev.Attr, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Abbrev.Attr, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.Abbrev, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.AlignedManaged(debug.Dwarf.Abbrev, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.Abbrev.Table, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.Abbrev.Table, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.Func, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.Func, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_17196(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_17197(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(debug.Dwarf.CompileUnit, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(debug.Dwarf.CompileUnit, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).setCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).capacityInBytes"(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).allocatedBytes"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i7 @math.log2_int_ceil__anon_17322(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_17333(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeaderGeneric__anon_17340"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeaderGeneric__anon_17341"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).insertAllEntriesIntoNewHeaderGeneric__anon_17342"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i32 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CommonInformationEntry, array_hash_map.AutoContext(u64), false).checkedHash__anon_17347"(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @meta.eql__anon_17348(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i65 @math.ceilPowerOfTwoPromote__anon_17362(ptr nonnull, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #1

; Function Attrs: cold noreturn nounwind uwtable
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).shiftRhsTooBig"(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_17367(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.readv(ptr nonnull, i32, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).Slice.items__anon_17393"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).checkedEql__anon_17396"(ptr nonnull, i64, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getIndexWithHeaderGeneric__anon_17402"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getIndexWithHeaderGeneric__anon_17403"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getIndexWithHeaderGeneric__anon_17404"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).addOneAssumeCapacity"(ptr nonnull, ptr nonnull align 8)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getOrPutInternal__anon_17414"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 4)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getOrPutInternal__anon_17415"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 4)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getOrPutInternal__anon_17416"(ptr noalias nonnull sret(%"array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).GetOrPutResult"), ptr nonnull, ptr nonnull align 8, i64, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.insertionContext__anon_17417(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.heapContext__anon_17418(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: cold nounwind uwtable
declare fastcc void @sort.pdq.breakPatterns__anon_17419(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i2 @sort.pdq.chosePivot__anon_17421(ptr nonnull, i64, i64, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.reverseRange__anon_17422(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: cold nounwind uwtable
declare fastcc i1 @sort.pdq.partialInsertionSort__anon_17424(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).sortInternal__anon_14622__struct_16215.lessThan"(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @sort.pdq.partitionEqual__anon_17430(ptr nonnull, i64, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @sort.pdq.partition__anon_17432(ptr nonnull, i64, i64, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.asBytes__anon_17439(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Thread.Futex.LinuxImpl.wake(ptr nonnull, ptr nonnull readonly align 4, i32)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_17457(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_17459(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_17463(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_17467(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_17469(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i32)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printIntAny__anon_17471(ptr nonnull, ptr nonnull align 8, i64, i8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.printIntAny__anon_17473(ptr nonnull, ptr nonnull align 8, i32, i8, i1, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Reader.rebase(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.Dwarf.Abbrev.Table, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_17549(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_17553(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_17556(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.Dwarf.Func, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_17566(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_17570(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_17573(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_17579(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(debug.Dwarf.CompileUnit, null).allocatedSlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.Allocator.remap__anon_17589(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.alignedAlloc__anon_17593(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.free__anon_17596(ptr nonnull, ptr nonnull readonly align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i6 @math.log2_int__anon_17599(ptr nonnull, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i7, i1 } @llvm.uadd.with.overflow.i7(i7, i7) #1

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_17603(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).setCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getSlotByKey__anon_17631"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4, ptr nonnull align 1, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getSlotByKey__anon_17633"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4, ptr nonnull align 2, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc void @"array_hash_map.ArrayHashMapUnmanaged(u64, debug.Dwarf.CompileUnit.SrcLocCache.LineEntry, array_hash_map.AutoContext(u64), false).getSlotByKey__anon_17635"(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, ptr nonnull align 4, ptr nonnull align 4, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).sortInternal__anon_14622__struct_16215.swap"(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.siftDown__anon_17641(ptr nonnull, i64, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.pdq.sort3__anon_17643(ptr nonnull, i64, i64, i64, ptr nonnull align 8, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @debug.Dwarf.runLineNumberProgram__struct_7020.lessThan(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.futex_3arg(ptr nonnull, ptr nonnull readonly align 1, i32, i32)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_17665(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #1

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_17674(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_17678(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_17689(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_17693(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.sliceAsBytes__anon_17708(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @mem.bytesAsSlice__anon_17712(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocWithSizeAndAlignment__anon_17714(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.Allocator.allocBytesWithAlignment__anon_17719(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.swap__anon_17723(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.swap__anon_17725(ptr nonnull, ptr nonnull align 4, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(usize, *debug.Dwarf.ElfModule, hash_map.AutoContext(usize), 80).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CompileUnit.SrcLocCache.LineEntry,array_hash_map.AutoContext(u64),false).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,debug.Dwarf.CommonInformationEntry,array_hash_map.AutoContext(u64),false).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc ptr @heap.PageAllocator.alloc(ptr nonnull, ptr nonnull align 1, i64, i6, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @heap.PageAllocator.map(ptr nonnull, i64, i6)

; Function Attrs: nounwind uwtable
declare fastcc i1 @heap.PageAllocator.resize(ptr nonnull, ptr nonnull align 1, ptr nonnull align 1, i64, i6, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @heap.PageAllocator.realloc(ptr nonnull, ptr nonnull align 1, i64, i64, i1)

; Function Attrs: nounwind uwtable
declare fastcc ptr @heap.PageAllocator.remap(ptr nonnull, ptr nonnull align 1, ptr nonnull align 1, i64, i6, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @heap.PageAllocator.free(ptr nonnull, ptr nonnull align 1, ptr nonnull align 1, i64, i6, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @heap.PageAllocator.unmap(ptr nonnull, ptr nonnull align 4096, i64)

; Function Attrs: nounwind uwtable
declare fastcc ptr @mem.alignPointer__anon_18088(ptr nonnull, ptr nonnull align 4096, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.mremap(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr align 4096, i64, i64, i32, ptr align 4096)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.alignPointerOffset__anon_18107(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, ptr nonnull align 4096, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.mremap(ptr nonnull, ptr readonly align 1, i64, i64, i32, ptr readonly align 1)

; Function Attrs: nounwind uwtable
declare fastcc i1 @mem.isValidAlign(ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.Writer.sendFile(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @Io.Reader.buffered(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.Writer.sendFileBuffered(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @math.cast__anon_18164(ptr noalias nonnull sret({ i64, i8, [7 x i8] }), ptr nonnull, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @os.linux.wrapped.sendfile(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, i32, ptr align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @os.linux.wrapped.copy_file_range(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, ptr align 8, i32, ptr align 8, i64, i32)

; Function Attrs: nounwind uwtable
declare fastcc void @fs.File.Writer.drain(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.pwritev(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @fs.File.Writer.seekTo(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Writer.consume(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @posix.writev(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, i32, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.sendfile(ptr nonnull, i32, i32, ptr align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @os.linux.wrapped.errno__anon_18218(ptr nonnull, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc i16 @os.linux.wrapped.invalidApiUsage(ptr nonnull)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.copy_file_range(ptr nonnull, i32, ptr align 8, i32, ptr align 8, i64, i32)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.pwritev(ptr nonnull, i32, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @posix.lseek_SET(ptr nonnull, i32, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @os.linux.writev(ptr nonnull, i32, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.streamDirect(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.streamFallible(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @compress.flate.Decompress.rebaseFallible(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.rebase(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.discardDirect(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.readVec(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.streamIndirectInner(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
define internal fastcc void @compress.flate.Decompress.streamInner(ptr noalias nonnull sret({ i64, i16, [6 x i8] }) %0, ptr nonnull %1, ptr nonnull align 8 %2, ptr nonnull align 8 %3, i64 %4) unnamed_addr #0 {
Entry:
  %5 = alloca { i64, i16, [6 x i8] }, align 8
  %6 = alloca { i64, i16, [6 x i8] }, align 8
  %7 = alloca { i32, i16, [2 x i8] }, align 4
  %8 = alloca i32, align 4
  %9 = alloca i1, align 1
  %10 = alloca ptr, align 8
  %11 = alloca { i32, i16, [2 x i8] }, align 4
  %12 = alloca { ptr, i16, [6 x i8] }, align 8
  %13 = alloca i16, align 2
  %14 = alloca ptr, align 8
  %15 = alloca i1, align 1
  %16 = alloca ptr, align 8
  %17 = alloca ptr, align 8
  %18 = alloca { i64, i16, [6 x i8] }, align 8
  %19 = alloca { i32, i16, [2 x i8] }, align 4
  %20 = alloca i32, align 4
  %21 = alloca i1, align 1
  %22 = alloca ptr, align 8
  %23 = alloca { i32, i16, [2 x i8] }, align 4
  %24 = alloca { ptr, i16, [6 x i8] }, align 8
  %25 = alloca i16, align 2
  %26 = alloca ptr, align 8
  %27 = alloca i1, align 1
  %28 = alloca ptr, align 8
  %29 = alloca { i64, i16, [6 x i8] }, align 8
  %30 = alloca { i32, i16, [2 x i8] }, align 4
  %31 = alloca i32, align 4
  %32 = alloca i1, align 1
  %33 = alloca ptr, align 8
  %34 = alloca { i32, i16, [2 x i8] }, align 4
  %35 = alloca { ptr, i16, [6 x i8] }, align 8
  %36 = alloca i16, align 2
  %37 = alloca ptr, align 8
  %38 = alloca i1, align 1
  %39 = alloca ptr, align 8
  %40 = alloca ptr, align 8
  %41 = alloca { i64, i16, [6 x i8] }, align 8
  %42 = alloca { i64, i16, [6 x i8] }, align 8
  %43 = alloca i16, align 2
  %44 = alloca { i64, i16, [6 x i8] }, align 8
  %45 = alloca { i16, i16 }, align 2
  %46 = alloca i46, align 8
  %47 = alloca { i64, i16, [6 x i8] }, align 8
  %48 = alloca { i46, i16, [6 x i8] }, align 8
  %49 = alloca i16, align 2
  %50 = alloca { i64, i16, [6 x i8] }, align 8
  %51 = alloca i8, align 1
  %52 = alloca %compress.flate.Decompress.State, align 2
  %53 = alloca %compress.flate.Decompress.State, align 2
  %54 = alloca i16, align 2
  %55 = alloca { i64, i16, [6 x i8] }, align 8
  %56 = alloca { i16, i16 }, align 2
  %57 = alloca { i64, i16, [6 x i8] }, align 8
  %58 = alloca { i64, i16, [6 x i8] }, align 8
  %59 = alloca { i46, i16, [6 x i8] }, align 8
  %60 = alloca { i64, i16, [6 x i8] }, align 8
  %61 = alloca { i64, i16, [6 x i8] }, align 8
  %62 = alloca { i46, i16, [6 x i8] }, align 8
  %63 = alloca i46, align 8
  %64 = alloca { i64, i16, [6 x i8] }, align 8
  %65 = alloca { i64, i16, [6 x i8] }, align 8
  %66 = alloca i16, align 2
  %67 = alloca { i64, i16, [6 x i8] }, align 8
  %68 = alloca { i16, i16 }, align 2
  %69 = alloca { i64, i16, [6 x i8] }, align 8
  %70 = alloca { i16, i5, [1 x i8] }, align 2
  %71 = alloca i16, align 2
  %72 = alloca { i64, i16, [6 x i8] }, align 8
  %73 = alloca { i16, i16 }, align 2
  %74 = alloca { i64, i16, [6 x i8] }, align 8
  %75 = alloca { i64, i16, [6 x i8] }, align 8
  %76 = alloca i16, align 2
  %77 = alloca { i64, i16, [6 x i8] }, align 8
  %78 = alloca { i16, i16 }, align 2
  %79 = alloca { i64, i16, [6 x i8] }, align 8
  %80 = alloca i64, align 8
  %81 = alloca { i64, i16, [6 x i8] }, align 8
  %82 = alloca { i64, i16, [6 x i8] }, align 8
  %83 = alloca i64, align 8
  %84 = alloca [1 x { ptr, i64 }], align 8
  %85 = alloca { ptr, i64 }, align 8
  %86 = alloca { i64, i16, [6 x i8] }, align 8
  %87 = alloca { { ptr, i64 }, i16, [6 x i8] }, align 8
  %88 = alloca i16, align 2
  %89 = alloca { i64, i16, [6 x i8] }, align 8
  %90 = alloca { ptr, i64 }, align 8
  %91 = alloca { i64, i16, [6 x i8] }, align 8
  %92 = alloca { ptr, i64 }, align 8
  %93 = alloca { i64, i16, [6 x i8] }, align 8
  %94 = alloca { i64, i16, [6 x i8] }, align 8
  %95 = alloca { i64, i16, [6 x i8] }, align 8
  %96 = alloca i46, align 8
  %97 = alloca { i64, i16, [6 x i8] }, align 8
  %98 = alloca { i46, i16, [6 x i8] }, align 8
  %99 = alloca i7, align 1
  %100 = alloca { i64, i16, [6 x i8] }, align 8
  %101 = alloca { i16, i7, [1 x i8] }, align 2
  %102 = alloca i64, align 8
  %103 = alloca [316 x i4], align 1
  %104 = alloca { i64, i16, [6 x i8] }, align 8
  %105 = alloca [6 x i64], align 8
  %106 = alloca %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", align 8
  %107 = alloca { i64, i16, [6 x i8] }, align 8
  %108 = alloca { i16, i3, [1 x i8] }, align 2
  %109 = alloca i32, align 4
  %110 = alloca i64, align 8
  %111 = alloca [19 x i4], align 1
  %112 = alloca i8, align 1
  %113 = alloca { i64, i16, [6 x i8] }, align 8
  %114 = alloca { i16, i4, [1 x i8] }, align 2
  %115 = alloca i16, align 2
  %116 = alloca { i64, i16, [6 x i8] }, align 8
  %117 = alloca { i16, i5, [1 x i8] }, align 2
  %118 = alloca i16, align 2
  %119 = alloca { i64, i16, [6 x i8] }, align 8
  %120 = alloca { i16, i5, [1 x i8] }, align 2
  %121 = alloca %compress.flate.Decompress.State, align 2
  %122 = alloca i16, align 2
  %123 = alloca { i64, i16, [6 x i8] }, align 8
  %124 = alloca { i16, i16 }, align 2
  %125 = alloca i16, align 2
  %126 = alloca i1, align 1
  %127 = alloca ptr, align 8
  %128 = alloca { i16, i16 }, align 2
  %129 = alloca { ptr, i16, [6 x i8] }, align 8
  %130 = alloca i16, align 2
  %131 = alloca ptr, align 8
  %132 = alloca i1, align 1
  %133 = alloca ptr, align 8
  %134 = alloca i16, align 2
  %135 = alloca { i64, i16, [6 x i8] }, align 8
  %136 = alloca { i16, i16 }, align 2
  %137 = alloca i16, align 2
  %138 = alloca i1, align 1
  %139 = alloca ptr, align 8
  %140 = alloca { i16, i16 }, align 2
  %141 = alloca { ptr, i16, [6 x i8] }, align 8
  %142 = alloca i16, align 2
  %143 = alloca ptr, align 8
  %144 = alloca i1, align 1
  %145 = alloca ptr, align 8
  %146 = alloca i2, align 1
  %147 = alloca { i64, i16, [6 x i8] }, align 8
  %148 = alloca { i16, i2, [1 x i8] }, align 2
  %149 = alloca { i64, i16, [6 x i8] }, align 8
  %150 = alloca { i16, i1, [1 x i8] }, align 2
  %151 = alloca i8, align 1
  %152 = alloca ptr, align 8
  %153 = alloca { i64, i16, [6 x i8] }, align 8
  %154 = alloca { ptr, i16, [6 x i8] }, align 8
  %155 = alloca { i64, i16, [6 x i8] }, align 8
  %156 = alloca { i64, i16, [6 x i8] }, align 8
  %157 = alloca { i64, i16, [6 x i8] }, align 8
  %158 = alloca { i64, i16, [6 x i8] }, align 8
  %159 = alloca { i64, i16, [6 x i8] }, align 8
  %160 = alloca { i64, i16, [6 x i8] }, align 8
  %161 = alloca i16, align 2
  %162 = alloca { i64, i16, [6 x i8] }, align 8
  %163 = alloca { i16, i16 }, align 2
  %164 = alloca i16, align 2
  %165 = alloca i1, align 1
  %166 = alloca ptr, align 8
  %167 = alloca { i16, i16 }, align 2
  %168 = alloca { ptr, i16, [6 x i8] }, align 8
  %169 = alloca i16, align 2
  %170 = alloca ptr, align 8
  %171 = alloca i1, align 1
  %172 = alloca ptr, align 8
  %173 = alloca %compress.flate.Decompress.streamInner.Header, align 1
  %174 = alloca { i64, i16, [6 x i8] }, align 8
  %175 = alloca { i16, %compress.flate.Decompress.streamInner.Header }, align 2
  %176 = alloca { i16, %compress.flate.Decompress.streamInner.Header }, align 2
  %177 = alloca { ptr, i16, [6 x i8] }, align 8
  %178 = alloca %compress.flate.Decompress.streamInner.Header, align 1
  %179 = alloca ptr, align 8
  %180 = alloca i1, align 1
  %181 = alloca ptr, align 8
  %182 = alloca %compress.flate.Decompress.State, align 2
  %183 = alloca ptr, align 8
  %184 = alloca ptr, align 8
  %185 = alloca i64, align 8
  %186 = alloca i64, align 8
  %187 = alloca ptr, align 8
  %188 = alloca ptr, align 8
  %189 = alloca i64, align 8
  %190 = alloca ptr, align 8
  %191 = alloca ptr, align 8
  store ptr %2, ptr %191, align 8
  store ptr %3, ptr %190, align 8
  store i64 %4, ptr %189, align 8
  store ptr %2, ptr %188, align 8
  store ptr %3, ptr %187, align 8
  store i64 %4, ptr %186, align 8
  store i64 %4, ptr %185, align 8
  %192 = getelementptr inbounds %compress.flate.Decompress, ptr %2, i32 0, i32 0
  %193 = load ptr, ptr %192, align 8
  store ptr %193, ptr %184, align 8
  store ptr %193, ptr %183, align 8
  %194 = getelementptr inbounds %compress.flate.Decompress, ptr %2, i32 0, i32 6
  %195 = getelementptr inbounds %compress.flate.Decompress.State, ptr %194, i32 0, i32 1
  %196 = load i4, ptr %195, align 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 %194, i64 4, i1 false)
  %197 = icmp uge i4 %196, 0
  %198 = icmp ule i4 %196, -8
  %199 = and i1 %197, %198
  br i1 %199, label %Then, label %Default

Case:                                             ; preds = %Then38, %Then35, %Then11, %Then
  %200 = load ptr, ptr %188, align 8
  %201 = getelementptr inbounds %compress.flate.Decompress, ptr %200, i32 0, i32 5
  %202 = call fastcc i2 @compress.flate.Container.Metadata.container(ptr %1, ptr nonnull readonly align 4 %201)
  switch i2 %202, label %Default1 [
    i2 1, label %Case9
    i2 -2, label %Case10
    i2 0, label %Case11
  ]

Case1:                                            ; preds = %Then38, %Then35, %Then11, %Block9, %Block8, %Case11, %Then
  %203 = load ptr, ptr %188, align 8
  %204 = getelementptr inbounds %compress.flate.Decompress, ptr %203, i32 0, i32 9
  %205 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.takeBits__anon_18482(ptr sret({ i16, i1, [1 x i8] }) %150, ptr %1, ptr nonnull align 8 %205)
  %206 = getelementptr inbounds { i16, i1, [1 x i8] }, ptr %150, i32 0, i32 0
  %207 = load i16, ptr %206, align 2
  %208 = icmp ne i16 %207, 0
  br i1 %208, label %TryRet9, label %TryCont9

Case2:                                            ; preds = %Then38, %Then35, %Then11, %Then
  %209 = getelementptr inbounds %compress.flate.Decompress.State, ptr %182, i32 0, i32 0
  %210 = load i16, ptr %209, align 2
  store i16 %210, ptr %88, align 2
  %211 = load ptr, ptr %187, align 8
  call fastcc void @Io.Writer.writableSliceGreedyPreserve(ptr sret({ { ptr, i64 }, i16, [6 x i8] }) %87, ptr %1, ptr nonnull align 8 %211, i64 32768, i64 1)
  %212 = getelementptr inbounds { { ptr, i64 }, i16, [6 x i8] }, ptr %87, i32 0, i32 1
  %213 = load i16, ptr %212, align 2
  %214 = icmp ne i16 %213, 0
  br i1 %214, label %TryRet26, label %TryCont26

Case3:                                            ; preds = %Then38, %Then35, %Then11, %Case13, %Then
  br label %Loop2

Case4:                                            ; preds = %TryCont41, %TryCont38, %Then38, %Then35, %TryCont25, %Then11, %Then
  %215 = load ptr, ptr %188, align 8
  %216 = load ptr, ptr %188, align 8
  %217 = getelementptr inbounds %compress.flate.Decompress, ptr %216, i32 0, i32 3
  call fastcc void @compress.flate.Decompress.decodeSymbol__anon_18911(ptr sret({ i46, i16, [6 x i8] }) %62, ptr %1, ptr nonnull align 8 %215, ptr nonnull align 8 %217)
  %218 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %62, i32 0, i32 1
  %219 = load i16, ptr %218, align 2
  %220 = icmp ne i16 %219, 0
  br i1 %220, label %TryRet34, label %TryCont34

Case5:                                            ; preds = %Then38, %Then35, %Then11, %Then
  %221 = getelementptr inbounds %compress.flate.Decompress.State, ptr %182, i32 0, i32 0
  %222 = load i8, ptr %221, align 2
  store i8 %222, ptr %51, align 1
  %223 = load i64, ptr %185, align 8
  %224 = icmp ne i64 %223, 0
  call fastcc void @debug.assert(ptr %1, i1 %224)
  %225 = load i64, ptr %185, align 8
  %226 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %225, i64 1)
  %227 = extractvalue { i64, i1 } %226, 1
  br i1 %227, label %OverflowFail17, label %OverflowOk17

Case6:                                            ; preds = %Then38, %Then35, %Then11, %Then
  %228 = getelementptr inbounds %compress.flate.Decompress.State, ptr %182, i32 0, i32 0
  %229 = load i16, ptr %228, align 2
  store i16 %229, ptr %49, align 2
  %230 = load i64, ptr %185, align 8
  %231 = zext i16 %229 to i64
  %232 = icmp uge i64 %230, %231
  br i1 %232, label %Then39, label %Else33

Case7:                                            ; preds = %Then38, %Then35, %Then11, %Then
  %233 = load ptr, ptr %188, align 8
  %234 = getelementptr inbounds %compress.flate.Decompress, ptr %233, i32 0, i32 5
  %235 = getelementptr inbounds %compress.flate.Container.Metadata, ptr %234, i32 0, i32 1
  %236 = load i2, ptr %235, align 1
  switch i2 %236, label %Default5 [
    i2 1, label %Case22
    i2 -2, label %Case23
    i2 0, label %Case24
  ]

Case8:                                            ; preds = %Then38, %Then35, %Then11, %Then
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @640, i64 16, i1 false)
  ret void

Default:                                          ; preds = %Block44, %Block42, %Block16, %Entry
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Then:                                             ; preds = %Entry
  %237 = sub nuw i4 %196, 0
  %238 = zext i4 %237 to i64
  %239 = getelementptr inbounds ptr, ptr @__jmptab_1412, i64 %238
  %240 = load ptr, ptr %239, align 8
  indirectbr ptr %240, [label %Case, label %Case1, label %Case2, label %Case3, label %Case4, label %Case5, label %Case6, label %Case7, label %Case8]

Case9:                                            ; preds = %Case
  %241 = load ptr, ptr %184, align 8
  store ptr %241, ptr %181, align 8
  store i1 true, ptr %180, align 1
  store ptr %241, ptr %179, align 8
  %242 = load ptr, ptr %179, align 8
  call fastcc void @Io.Reader.takeStructPointer__anon_18452(ptr sret({ ptr, i16, [6 x i8] }) %177, ptr %1, ptr nonnull align 8 %242)
  %243 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %177, i32 0, i32 1
  %244 = load i16, ptr %243, align 2
  %245 = icmp ne i16 %244, 0
  br i1 %245, label %TryRet, label %TryCont

Case10:                                           ; preds = %Case
  %246 = load ptr, ptr %184, align 8
  call fastcc void @Io.Reader.takeArray__anon_18463(ptr sret({ ptr, i16, [6 x i8] }) %154, ptr %1, ptr nonnull align 8 %246)
  %247 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %154, i32 0, i32 1
  %248 = load i16, ptr %247, align 2
  %249 = icmp ne i16 %248, 0
  br i1 %249, label %TryRet8, label %TryCont8

Case11:                                           ; preds = %Case
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 @628, i64 4, i1 false)
  br label %Case1

Default1:                                         ; preds = %Case
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Block:                                            ; preds = %TryCont, %TryRet
  %250 = phi ptr [ %176, %TryRet ], [ %175, %TryCont ]
  %251 = getelementptr inbounds { i16, %compress.flate.Decompress.streamInner.Header }, ptr %250, i32 0, i32 0
  %252 = load i16, ptr %251, align 2
  %253 = icmp ne i16 %252, 0
  br i1 %253, label %TryRet1, label %TryCont1

TryRet:                                           ; preds = %Case9
  %254 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %177, i32 0, i32 1
  %255 = load i16, ptr %254, align 2
  %256 = getelementptr inbounds { i16, %compress.flate.Decompress.streamInner.Header }, ptr %176, i32 0, i32 0
  store i16 %255, ptr %256, align 2
  %257 = getelementptr inbounds { i16, %compress.flate.Decompress.streamInner.Header }, ptr %176, i32 0, i32 1
  br label %Block

TryCont:                                          ; preds = %Case9
  %258 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %177, i32 0, i32 0
  %259 = load ptr, ptr %258, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %178, ptr align 1 %259, i64 10, i1 false)
  %260 = getelementptr inbounds { i16, %compress.flate.Decompress.streamInner.Header }, ptr %175, i32 0, i32 0
  store i16 0, ptr %260, align 2
  %261 = getelementptr inbounds { i16, %compress.flate.Decompress.streamInner.Header }, ptr %175, i32 0, i32 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %261, ptr align 1 %178, i64 10, i1 false)
  br label %Block

TryRet1:                                          ; preds = %Block
  %262 = getelementptr inbounds { i16, %compress.flate.Decompress.streamInner.Header }, ptr %250, i32 0, i32 0
  %263 = load i16, ptr %262, align 2
  %264 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %174, i32 0, i32 1
  store i16 %263, ptr %264, align 2
  %265 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %174, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %174, i64 16, i1 false)
  ret void

TryCont1:                                         ; preds = %Block
  %266 = getelementptr inbounds { i16, %compress.flate.Decompress.streamInner.Header }, ptr %250, i32 0, i32 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %173, ptr align 1 %266, i64 10, i1 false)
  %267 = getelementptr inbounds %compress.flate.Decompress.streamInner.Header, ptr %173, i32 0, i32 0
  %268 = load i16, ptr %267, align 1
  %269 = icmp ne i16 %268, -29921
  br i1 %269, label %Then1, label %Else

Block1:                                           ; preds = %Else1
  %270 = getelementptr inbounds %compress.flate.Decompress.streamInner.Header, ptr %173, i32 0, i32 2
  %271 = load i8, ptr %270, align 1
  %272 = lshr i8 %271, 2
  %273 = trunc i8 %272 to i1
  br i1 %273, label %Then3, label %Else2

Block2:                                           ; preds = %Else, %Then1
  %274 = phi i1 [ true, %Then1 ], [ %277, %Else ]
  br i1 %274, label %Then2, label %Else1

Then1:                                            ; preds = %TryCont1
  br label %Block2

Else:                                             ; preds = %TryCont1
  %275 = getelementptr inbounds %compress.flate.Decompress.streamInner.Header, ptr %173, i32 0, i32 1
  %276 = load i8, ptr %275, align 1
  %277 = icmp ne i8 %276, 8
  br label %Block2

Then2:                                            ; preds = %Block2
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @627, i64 16, i1 false)
  ret void

Else1:                                            ; preds = %Block2
  br label %Block1

Block3:                                           ; preds = %TryCont4, %Else2
  %278 = getelementptr inbounds %compress.flate.Decompress.streamInner.Header, ptr %173, i32 0, i32 2
  %279 = load i8, ptr %278, align 1
  %280 = lshr i8 %279, 3
  %281 = trunc i8 %280 to i1
  br i1 %281, label %Then4, label %Else3

Then3:                                            ; preds = %Block1
  %282 = load ptr, ptr %184, align 8
  store ptr %282, ptr %172, align 8
  store i1 true, ptr %171, align 1
  store ptr %282, ptr %170, align 8
  store i16 2, ptr %169, align 2
  %283 = load ptr, ptr %170, align 8
  call fastcc void @Io.Reader.takeArray__anon_18463(ptr sret({ ptr, i16, [6 x i8] }) %168, ptr %1, ptr nonnull align 8 %283)
  %284 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %168, i32 0, i32 1
  %285 = load i16, ptr %284, align 2
  %286 = icmp ne i16 %285, 0
  br i1 %286, label %TryRet2, label %TryCont2

Else2:                                            ; preds = %Block1
  br label %Block3

Block4:                                           ; preds = %Block5, %TryRet2
  %287 = phi ptr [ %167, %TryRet2 ], [ %163, %Block5 ]
  %288 = getelementptr inbounds { i16, i16 }, ptr %287, i32 0, i32 1
  %289 = load i16, ptr %288, align 2
  %290 = icmp ne i16 %289, 0
  br i1 %290, label %TryRet3, label %TryCont3

TryRet2:                                          ; preds = %Then3
  %291 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %168, i32 0, i32 1
  %292 = load i16, ptr %291, align 2
  %293 = getelementptr inbounds { i16, i16 }, ptr %167, i32 0, i32 1
  store i16 %292, ptr %293, align 2
  %294 = getelementptr inbounds { i16, i16 }, ptr %167, i32 0, i32 0
  br label %Block4

TryCont2:                                         ; preds = %Then3
  %295 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %168, i32 0, i32 0
  %296 = load ptr, ptr %295, align 8
  store ptr %296, ptr %166, align 8
  store i1 true, ptr %165, align 1
  %297 = load i16, ptr %296, align 1
  store i16 %297, ptr %164, align 2
  br label %Block5

Block5:                                           ; preds = %TryCont2
  %298 = phi i16 [ %297, %TryCont2 ]
  %299 = getelementptr inbounds { i16, i16 }, ptr %163, i32 0, i32 1
  store i16 0, ptr %299, align 2
  %300 = getelementptr inbounds { i16, i16 }, ptr %163, i32 0, i32 0
  store i16 %298, ptr %300, align 2
  br label %Block4

TryRet3:                                          ; preds = %Block4
  %301 = getelementptr inbounds { i16, i16 }, ptr %287, i32 0, i32 1
  %302 = load i16, ptr %301, align 2
  %303 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %162, i32 0, i32 1
  store i16 %302, ptr %303, align 2
  %304 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %162, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %162, i64 16, i1 false)
  ret void

TryCont3:                                         ; preds = %Block4
  %305 = getelementptr inbounds { i16, i16 }, ptr %287, i32 0, i32 0
  %306 = load i16, ptr %305, align 2
  store i16 %306, ptr %161, align 2
  %307 = load ptr, ptr %184, align 8
  %308 = zext i16 %306 to i64
  %309 = call fastcc i16 @Io.Reader.discardAll(ptr %1, ptr nonnull align 8 %307, i64 %308)
  %310 = icmp ne i16 %309, 0
  br i1 %310, label %TryRet4, label %TryCont4

TryRet4:                                          ; preds = %TryCont3
  %311 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %160, i32 0, i32 1
  store i16 %309, ptr %311, align 2
  %312 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %160, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %160, i64 16, i1 false)
  ret void

TryCont4:                                         ; preds = %TryCont3
  br label %Block3

Block6:                                           ; preds = %TryCont5, %Else3
  %313 = getelementptr inbounds %compress.flate.Decompress.streamInner.Header, ptr %173, i32 0, i32 2
  %314 = load i8, ptr %313, align 1
  %315 = lshr i8 %314, 4
  %316 = trunc i8 %315 to i1
  br i1 %316, label %Then5, label %Else4

Then4:                                            ; preds = %Block3
  %317 = load ptr, ptr %184, align 8
  call fastcc void @Io.Reader.discardDelimiterInclusive(ptr sret({ i64, i16, [6 x i8] }) %159, ptr %1, ptr nonnull align 8 %317, i8 0)
  %318 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %159, i32 0, i32 1
  %319 = load i16, ptr %318, align 2
  %320 = icmp ne i16 %319, 0
  br i1 %320, label %TryRet5, label %TryCont5

Else3:                                            ; preds = %Block3
  br label %Block6

TryRet5:                                          ; preds = %Then4
  %321 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %159, i32 0, i32 1
  %322 = load i16, ptr %321, align 2
  %323 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %158, i32 0, i32 1
  store i16 %322, ptr %323, align 2
  %324 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %158, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %158, i64 16, i1 false)
  ret void

TryCont5:                                         ; preds = %Then4
  br label %Block6

Block7:                                           ; preds = %TryCont6, %Else4
  %325 = getelementptr inbounds %compress.flate.Decompress.streamInner.Header, ptr %173, i32 0, i32 2
  %326 = load i8, ptr %325, align 1
  %327 = lshr i8 %326, 1
  %328 = trunc i8 %327 to i1
  br i1 %328, label %Then6, label %Else5

Then5:                                            ; preds = %Block6
  %329 = load ptr, ptr %184, align 8
  call fastcc void @Io.Reader.discardDelimiterInclusive(ptr sret({ i64, i16, [6 x i8] }) %157, ptr %1, ptr nonnull align 8 %329, i8 0)
  %330 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %157, i32 0, i32 1
  %331 = load i16, ptr %330, align 2
  %332 = icmp ne i16 %331, 0
  br i1 %332, label %TryRet6, label %TryCont6

Else4:                                            ; preds = %Block6
  br label %Block7

TryRet6:                                          ; preds = %Then5
  %333 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %157, i32 0, i32 1
  %334 = load i16, ptr %333, align 2
  %335 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %156, i32 0, i32 1
  store i16 %334, ptr %335, align 2
  %336 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %156, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %156, i64 16, i1 false)
  ret void

TryCont6:                                         ; preds = %Then5
  br label %Block7

Block8:                                           ; preds = %TryCont7, %Else5
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 @628, i64 4, i1 false)
  br label %Case1

Then6:                                            ; preds = %Block7
  %337 = load ptr, ptr %184, align 8
  %338 = call fastcc i16 @Io.Reader.discardAll(ptr %1, ptr nonnull align 8 %337, i64 2)
  %339 = icmp ne i16 %338, 0
  br i1 %339, label %TryRet7, label %TryCont7

Else5:                                            ; preds = %Block7
  br label %Block8

TryRet7:                                          ; preds = %Then6
  %340 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %155, i32 0, i32 1
  store i16 %338, ptr %340, align 2
  %341 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %155, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %155, i64 16, i1 false)
  ret void

TryCont7:                                         ; preds = %Then6
  br label %Block8

TryRet8:                                          ; preds = %Case10
  %342 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %154, i32 0, i32 1
  %343 = load i16, ptr %342, align 2
  %344 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %153, i32 0, i32 1
  store i16 %343, ptr %344, align 2
  %345 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %153, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %153, i64 16, i1 false)
  ret void

TryCont8:                                         ; preds = %Case10
  %346 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %154, i32 0, i32 0
  %347 = load ptr, ptr %346, align 8
  store ptr %347, ptr %152, align 8
  %348 = getelementptr inbounds [2 x i8], ptr %347, i64 0, i64 0
  %349 = load i8, ptr %348, align 1
  store i8 %349, ptr %151, align 1
  %350 = lshr i8 %349, 0
  %351 = trunc i8 %350 to i4
  %352 = icmp ne i4 %351, -8
  br i1 %352, label %Then7, label %Else6

Block9:                                           ; preds = %Else7
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 @628, i64 4, i1 false)
  br label %Case1

Block10:                                          ; preds = %Else6, %Then7
  %353 = phi i1 [ true, %Then7 ], [ %356, %Else6 ]
  br i1 %353, label %Then8, label %Else7

Then7:                                            ; preds = %TryCont8
  br label %Block10

Else6:                                            ; preds = %TryCont8
  %354 = lshr i8 %349, 4
  %355 = trunc i8 %354 to i4
  %356 = icmp ugt i4 %355, 7
  br label %Block10

Then8:                                            ; preds = %Block10
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @629, i64 16, i1 false)
  ret void

Else7:                                            ; preds = %Block10
  br label %Block9

TryRet9:                                          ; preds = %Case1
  %357 = getelementptr inbounds { i16, i1, [1 x i8] }, ptr %150, i32 0, i32 0
  %358 = load i16, ptr %357, align 2
  %359 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %149, i32 0, i32 1
  store i16 %358, ptr %359, align 2
  %360 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %149, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %149, i64 16, i1 false)
  ret void

TryCont9:                                         ; preds = %Case1
  %361 = getelementptr inbounds { i16, i1, [1 x i8] }, ptr %150, i32 0, i32 1
  %362 = load i1, ptr %361, align 1
  %363 = icmp ne i1 %362, false
  store i1 %363, ptr %204, align 1
  %364 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.takeBits__anon_18512(ptr sret({ i16, i2, [1 x i8] }) %148, ptr %1, ptr nonnull align 8 %364)
  %365 = getelementptr inbounds { i16, i2, [1 x i8] }, ptr %148, i32 0, i32 0
  %366 = load i16, ptr %365, align 2
  %367 = icmp ne i16 %366, 0
  br i1 %367, label %TryRet10, label %TryCont10

TryRet10:                                         ; preds = %TryCont9
  %368 = getelementptr inbounds { i16, i2, [1 x i8] }, ptr %148, i32 0, i32 0
  %369 = load i16, ptr %368, align 2
  %370 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %147, i32 0, i32 1
  store i16 %369, ptr %370, align 2
  %371 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %147, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %147, i64 16, i1 false)
  ret void

TryCont10:                                        ; preds = %TryCont9
  %372 = getelementptr inbounds { i16, i2, [1 x i8] }, ptr %148, i32 0, i32 1
  %373 = load i2, ptr %372, align 1
  %374 = call fastcc i1 @__zig_is_named_enum_value_compress.flate.Decompress.BlockType(i2 %373)
  br i1 %374, label %ValidEnumOk, label %ValidEnumFail

ValidEnumFail:                                    ; preds = %TryCont10
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).invalidEnumValue"(ptr %1)
  unreachable

ValidEnumOk:                                      ; preds = %TryCont10
  store i2 %373, ptr %146, align 1
  switch i2 %373, label %Default2 [
    i2 0, label %Case12
    i2 1, label %Case13
    i2 -2, label %Case14
    i2 -1, label %Case15
  ]

Case12:                                           ; preds = %ValidEnumOk
  %375 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.alignBitsDiscarding(ptr %1, ptr nonnull align 8 %375)
  %376 = load ptr, ptr %184, align 8
  store ptr %376, ptr %145, align 8
  store i1 true, ptr %144, align 1
  store ptr %376, ptr %143, align 8
  store i16 2, ptr %142, align 2
  %377 = load ptr, ptr %143, align 8
  call fastcc void @Io.Reader.takeArray__anon_18463(ptr sret({ ptr, i16, [6 x i8] }) %141, ptr %1, ptr nonnull align 8 %377)
  %378 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %141, i32 0, i32 1
  %379 = load i16, ptr %378, align 2
  %380 = icmp ne i16 %379, 0
  br i1 %380, label %TryRet11, label %TryCont11

Case13:                                           ; preds = %ValidEnumOk
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 @631, i64 4, i1 false)
  br label %Case3

Case14:                                           ; preds = %ValidEnumOk
  %381 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.takeBits__anon_18541(ptr sret({ i16, i5, [1 x i8] }) %120, ptr %1, ptr nonnull align 8 %381)
  %382 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %120, i32 0, i32 0
  %383 = load i16, ptr %382, align 2
  %384 = icmp ne i16 %383, 0
  br i1 %384, label %TryRet15, label %TryCont15

Case15:                                           ; preds = %ValidEnumOk
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @636, i64 16, i1 false)
  ret void

Default2:                                         ; preds = %ValidEnumOk
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Block11:                                          ; preds = %Block12, %TryRet11
  %385 = phi ptr [ %140, %TryRet11 ], [ %136, %Block12 ]
  %386 = getelementptr inbounds { i16, i16 }, ptr %385, i32 0, i32 1
  %387 = load i16, ptr %386, align 2
  %388 = icmp ne i16 %387, 0
  br i1 %388, label %TryRet12, label %TryCont12

TryRet11:                                         ; preds = %Case12
  %389 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %141, i32 0, i32 1
  %390 = load i16, ptr %389, align 2
  %391 = getelementptr inbounds { i16, i16 }, ptr %140, i32 0, i32 1
  store i16 %390, ptr %391, align 2
  %392 = getelementptr inbounds { i16, i16 }, ptr %140, i32 0, i32 0
  br label %Block11

TryCont11:                                        ; preds = %Case12
  %393 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %141, i32 0, i32 0
  %394 = load ptr, ptr %393, align 8
  store ptr %394, ptr %139, align 8
  store i1 true, ptr %138, align 1
  %395 = load i16, ptr %394, align 1
  store i16 %395, ptr %137, align 2
  br label %Block12

Block12:                                          ; preds = %TryCont11
  %396 = phi i16 [ %395, %TryCont11 ]
  %397 = getelementptr inbounds { i16, i16 }, ptr %136, i32 0, i32 1
  store i16 0, ptr %397, align 2
  %398 = getelementptr inbounds { i16, i16 }, ptr %136, i32 0, i32 0
  store i16 %396, ptr %398, align 2
  br label %Block11

TryRet12:                                         ; preds = %Block11
  %399 = getelementptr inbounds { i16, i16 }, ptr %385, i32 0, i32 1
  %400 = load i16, ptr %399, align 2
  %401 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %135, i32 0, i32 1
  store i16 %400, ptr %401, align 2
  %402 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %135, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %135, i64 16, i1 false)
  ret void

TryCont12:                                        ; preds = %Block11
  %403 = getelementptr inbounds { i16, i16 }, ptr %385, i32 0, i32 0
  %404 = load i16, ptr %403, align 2
  store i16 %404, ptr %134, align 2
  %405 = load ptr, ptr %184, align 8
  store ptr %405, ptr %133, align 8
  store i1 true, ptr %132, align 1
  store ptr %405, ptr %131, align 8
  store i16 2, ptr %130, align 2
  %406 = load ptr, ptr %131, align 8
  call fastcc void @Io.Reader.takeArray__anon_18463(ptr sret({ ptr, i16, [6 x i8] }) %129, ptr %1, ptr nonnull align 8 %406)
  %407 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %129, i32 0, i32 1
  %408 = load i16, ptr %407, align 2
  %409 = icmp ne i16 %408, 0
  br i1 %409, label %TryRet13, label %TryCont13

Block13:                                          ; preds = %Block14, %TryRet13
  %410 = phi ptr [ %128, %TryRet13 ], [ %124, %Block14 ]
  %411 = getelementptr inbounds { i16, i16 }, ptr %410, i32 0, i32 1
  %412 = load i16, ptr %411, align 2
  %413 = icmp ne i16 %412, 0
  br i1 %413, label %TryRet14, label %TryCont14

TryRet13:                                         ; preds = %TryCont12
  %414 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %129, i32 0, i32 1
  %415 = load i16, ptr %414, align 2
  %416 = getelementptr inbounds { i16, i16 }, ptr %128, i32 0, i32 1
  store i16 %415, ptr %416, align 2
  %417 = getelementptr inbounds { i16, i16 }, ptr %128, i32 0, i32 0
  br label %Block13

TryCont13:                                        ; preds = %TryCont12
  %418 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %129, i32 0, i32 0
  %419 = load ptr, ptr %418, align 8
  store ptr %419, ptr %127, align 8
  store i1 true, ptr %126, align 1
  %420 = load i16, ptr %419, align 1
  store i16 %420, ptr %125, align 2
  br label %Block14

Block14:                                          ; preds = %TryCont13
  %421 = phi i16 [ %420, %TryCont13 ]
  %422 = getelementptr inbounds { i16, i16 }, ptr %124, i32 0, i32 1
  store i16 0, ptr %422, align 2
  %423 = getelementptr inbounds { i16, i16 }, ptr %124, i32 0, i32 0
  store i16 %421, ptr %423, align 2
  br label %Block13

TryRet14:                                         ; preds = %Block13
  %424 = getelementptr inbounds { i16, i16 }, ptr %410, i32 0, i32 1
  %425 = load i16, ptr %424, align 2
  %426 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %123, i32 0, i32 1
  store i16 %425, ptr %426, align 2
  %427 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %123, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %123, i64 16, i1 false)
  ret void

TryCont14:                                        ; preds = %Block13
  %428 = getelementptr inbounds { i16, i16 }, ptr %410, i32 0, i32 0
  %429 = load i16, ptr %428, align 2
  store i16 %429, ptr %122, align 2
  %430 = xor i16 %429, -1
  %431 = icmp ne i16 %404, %430
  br i1 %431, label %Then9, label %Else8

Block15:                                          ; preds = %Else8
  %432 = getelementptr inbounds { i16, i4, [1 x i8] }, ptr %121, i64 0, i32 0
  store i16 %404, ptr %432, align 2
  %433 = getelementptr inbounds { i16, i4, [1 x i8] }, ptr %121, i64 0, i32 1
  store i4 2, ptr %433, align 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 %121, i64 4, i1 false)
  %434 = getelementptr inbounds %compress.flate.Decompress.State, ptr %121, i32 0, i32 1
  %435 = load i4, ptr %434, align 1
  %436 = call fastcc i1 @"__zig_is_named_enum_value_@typeInfo(compress.flate.Decompress.State).@\22union\22.tag_type.?"(i4 %435)
  br i1 %436, label %Then10, label %Else9

Then9:                                            ; preds = %TryCont14
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @630, i64 16, i1 false)
  ret void

Else8:                                            ; preds = %TryCont14
  br label %Block15

Block16:                                          ; preds = %Then10
  %437 = icmp uge i4 %435, 0
  %438 = icmp ule i4 %435, -8
  %439 = and i1 %437, %438
  br i1 %439, label %Then11, label %Default

Then10:                                           ; preds = %Block15
  br label %Block16

Else9:                                            ; preds = %Block15
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Then11:                                           ; preds = %Block16
  %440 = sub nuw i4 %435, 0
  %441 = zext i4 %440 to i64
  %442 = getelementptr inbounds ptr, ptr @__jmptab_1412, i64 %441
  %443 = load ptr, ptr %442, align 8
  indirectbr ptr %443, [label %Case, label %Case1, label %Case2, label %Case3, label %Case4, label %Case5, label %Case6, label %Case7, label %Case8]

TryRet15:                                         ; preds = %Case14
  %444 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %120, i32 0, i32 0
  %445 = load i16, ptr %444, align 2
  %446 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %119, i32 0, i32 1
  store i16 %445, ptr %446, align 2
  %447 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %119, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %119, i64 16, i1 false)
  ret void

TryCont15:                                        ; preds = %Case14
  %448 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %120, i32 0, i32 1
  %449 = load i5, ptr %448, align 1
  %450 = zext i5 %449 to i16
  %451 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %450, i16 257)
  %452 = extractvalue { i16, i1 } %451, 1
  br i1 %452, label %OverflowFail, label %OverflowOk

OverflowFail:                                     ; preds = %TryCont15
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk:                                       ; preds = %TryCont15
  %453 = extractvalue { i16, i1 } %451, 0
  store i16 %453, ptr %118, align 2
  %454 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.takeBits__anon_18541(ptr sret({ i16, i5, [1 x i8] }) %117, ptr %1, ptr nonnull align 8 %454)
  %455 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %117, i32 0, i32 0
  %456 = load i16, ptr %455, align 2
  %457 = icmp ne i16 %456, 0
  br i1 %457, label %TryRet16, label %TryCont16

TryRet16:                                         ; preds = %OverflowOk
  %458 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %117, i32 0, i32 0
  %459 = load i16, ptr %458, align 2
  %460 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %116, i32 0, i32 1
  store i16 %459, ptr %460, align 2
  %461 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %116, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %116, i64 16, i1 false)
  ret void

TryCont16:                                        ; preds = %OverflowOk
  %462 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %117, i32 0, i32 1
  %463 = load i5, ptr %462, align 1
  %464 = zext i5 %463 to i16
  %465 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %464, i16 1)
  %466 = extractvalue { i16, i1 } %465, 1
  br i1 %466, label %OverflowFail1, label %OverflowOk1

OverflowFail1:                                    ; preds = %TryCont16
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk1:                                      ; preds = %TryCont16
  %467 = extractvalue { i16, i1 } %465, 0
  store i16 %467, ptr %115, align 2
  %468 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.takeBits__anon_18554(ptr sret({ i16, i4, [1 x i8] }) %114, ptr %1, ptr nonnull align 8 %468)
  %469 = getelementptr inbounds { i16, i4, [1 x i8] }, ptr %114, i32 0, i32 0
  %470 = load i16, ptr %469, align 2
  %471 = icmp ne i16 %470, 0
  br i1 %471, label %TryRet17, label %TryCont17

TryRet17:                                         ; preds = %OverflowOk1
  %472 = getelementptr inbounds { i16, i4, [1 x i8] }, ptr %114, i32 0, i32 0
  %473 = load i16, ptr %472, align 2
  %474 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %113, i32 0, i32 1
  store i16 %473, ptr %474, align 2
  %475 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %113, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %113, i64 16, i1 false)
  ret void

TryCont17:                                        ; preds = %OverflowOk1
  %476 = getelementptr inbounds { i16, i4, [1 x i8] }, ptr %114, i32 0, i32 1
  %477 = load i4, ptr %476, align 1
  %478 = zext i4 %477 to i8
  %479 = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %478, i8 4)
  %480 = extractvalue { i8, i1 } %479, 1
  br i1 %480, label %OverflowFail2, label %OverflowOk2

OverflowFail2:                                    ; preds = %TryCont17
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk2:                                      ; preds = %TryCont17
  %481 = extractvalue { i8, i1 } %479, 0
  store i8 %481, ptr %112, align 1
  %482 = icmp ugt i16 %453, 286
  br i1 %482, label %Then12, label %Else10

Block17:                                          ; preds = %Else11
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %111, ptr align 1 @633, i64 19, i1 false)
  store i64 0, ptr %110, align 8
  %483 = zext i8 %481 to i64
  %484 = icmp ule i64 0, %483
  br i1 %484, label %Then14, label %Else12

Block18:                                          ; preds = %Else10, %Then12
  %485 = phi i1 [ true, %Then12 ], [ %486, %Else10 ]
  br i1 %485, label %Then13, label %Else11

Then12:                                           ; preds = %OverflowOk2
  br label %Block18

Else10:                                           ; preds = %OverflowOk2
  %486 = icmp ugt i16 %467, 30
  br label %Block18

Then13:                                           ; preds = %Block18
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @632, i64 16, i1 false)
  ret void

Else11:                                           ; preds = %Block18
  br label %Block17

Block19:                                          ; preds = %Then14
  %487 = sub nuw i64 %483, 0
  %488 = icmp ule i64 %483, 19
  br i1 %488, label %Then15, label %Else13

Then14:                                           ; preds = %Block17
  br label %Block19

Else12:                                           ; preds = %Block17
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).startGreaterThanEnd"(ptr %1, i64 0, i64 %483)
  unreachable

Block20:                                          ; preds = %Then15
  %489 = icmp ule i64 0, %483
  br i1 %489, label %Then16, label %Else14

Then15:                                           ; preds = %Block19
  br label %Block20

Else13:                                           ; preds = %Block19
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 %483, i64 19)
  unreachable

Block21:                                          ; preds = %Then16
  %490 = insertvalue { ptr, i64 } poison, ptr @compress.flate.HuffmanEncoder.codegen_order, 0
  %491 = insertvalue { ptr, i64 } %490, i64 %487, 1
  %492 = extractvalue { ptr, i64 } %491, 1
  br label %Loop

Then16:                                           ; preds = %Block20
  br label %Block21

Else14:                                           ; preds = %Block20
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 0, i64 %483)
  unreachable

Block22:                                          ; preds = %Else15
  call void @llvm.memset.p0.i64(ptr align 8 %106, i8 -86, i64 1176, i1 false)
  %493 = ptrtoint ptr %106 to i64
  %494 = getelementptr inbounds [6 x i64], ptr %105, i64 0, i64 0
  store i64 1296236545, ptr %494, align 8
  %495 = getelementptr inbounds [6 x i64], ptr %105, i64 0, i64 1
  store i64 %493, ptr %495, align 8
  %496 = getelementptr inbounds [6 x i64], ptr %105, i64 0, i64 2
  store i64 1176, ptr %496, align 8
  %497 = getelementptr inbounds [6 x i64], ptr %105, i64 0, i64 3
  store i64 0, ptr %497, align 8
  %498 = getelementptr inbounds [6 x i64], ptr %105, i64 0, i64 4
  store i64 0, ptr %498, align 8
  %499 = getelementptr inbounds [6 x i64], ptr %105, i64 0, i64 5
  store i64 0, ptr %499, align 8
  %500 = ptrtoint ptr %105 to i64
  %501 = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{edx},~{cc},~{memory}"(i64 %500, i64 0)
  %502 = getelementptr inbounds [19 x i4], ptr %111, i64 0, i64 0
  %503 = insertvalue { ptr, i64 } poison, ptr %502, 0
  %504 = insertvalue { ptr, i64 } %503, i64 19, 1
  %505 = extractvalue { ptr, i64 } %504, 0
  %506 = extractvalue { ptr, i64 } %504, 1
  %507 = call fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(19,7,7).generate"(ptr %1, ptr nonnull align 8 %106, ptr nonnull readonly align 1 %505, i64 %506)
  %508 = icmp ne i16 %507, 0
  br i1 %508, label %TryRet19, label %TryCont19

Loop:                                             ; preds = %Block23, %Block21
  %509 = load i64, ptr %110, align 8
  %510 = icmp ult i64 %509, %492
  br i1 %510, label %Then17, label %Else15

Block23:                                          ; preds = %TryCont18
  %511 = add nuw i64 %509, 1
  store i64 %511, ptr %110, align 8
  br label %Loop

Then17:                                           ; preds = %Loop
  %512 = extractvalue { ptr, i64 } %491, 0
  %513 = getelementptr inbounds i32, ptr %512, i64 %509
  %514 = load i32, ptr %513, align 4
  store i32 %514, ptr %109, align 4
  %515 = zext i32 %514 to i64
  %516 = icmp ult i64 %515, 19
  br i1 %516, label %Then18, label %Else16

Else15:                                           ; preds = %Loop
  br label %Block22

Block24:                                          ; preds = %Then18
  %517 = getelementptr inbounds [19 x i4], ptr %111, i64 0, i64 %515
  %518 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.takeBits__anon_18580(ptr sret({ i16, i3, [1 x i8] }) %108, ptr %1, ptr nonnull align 8 %518)
  %519 = getelementptr inbounds { i16, i3, [1 x i8] }, ptr %108, i32 0, i32 0
  %520 = load i16, ptr %519, align 2
  %521 = icmp ne i16 %520, 0
  br i1 %521, label %TryRet18, label %TryCont18

Then18:                                           ; preds = %Then17
  br label %Block24

Else16:                                           ; preds = %Then17
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 %515, i64 19)
  unreachable

TryRet18:                                         ; preds = %Block24
  %522 = getelementptr inbounds { i16, i3, [1 x i8] }, ptr %108, i32 0, i32 0
  %523 = load i16, ptr %522, align 2
  %524 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %107, i32 0, i32 1
  store i16 %523, ptr %524, align 2
  %525 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %107, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %107, i64 16, i1 false)
  ret void

TryCont18:                                        ; preds = %Block24
  %526 = getelementptr inbounds { i16, i3, [1 x i8] }, ptr %108, i32 0, i32 1
  %527 = load i3, ptr %526, align 1
  %528 = zext i3 %527 to i4
  store i4 %528, ptr %517, align 1
  br label %Block23

TryRet19:                                         ; preds = %Block22
  %529 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %104, i32 0, i32 1
  store i16 %507, ptr %529, align 2
  %530 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %104, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %104, i64 16, i1 false)
  ret void

TryCont19:                                        ; preds = %Block22
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %103, ptr align 1 @634, i64 316, i1 false)
  store i64 0, ptr %102, align 8
  br label %Loop1

Block25:                                          ; preds = %Else17
  %531 = load i64, ptr %102, align 8
  %532 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %453, i16 %467)
  %533 = extractvalue { i16, i1 } %532, 1
  br i1 %533, label %OverflowFail5, label %OverflowOk5

Loop1:                                            ; preds = %Block26, %TryCont19
  %534 = load i64, ptr %102, align 8
  %535 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %453, i16 %467)
  %536 = extractvalue { i16, i1 } %535, 1
  br i1 %536, label %OverflowFail3, label %OverflowOk3

Block26:                                          ; preds = %Block27
  br label %Loop1

OverflowFail3:                                    ; preds = %Loop1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk3:                                      ; preds = %Loop1
  %537 = extractvalue { i16, i1 } %535, 0
  %538 = zext i16 %537 to i64
  %539 = icmp ult i64 %534, %538
  br i1 %539, label %Then19, label %Else17

Then19:                                           ; preds = %OverflowOk3
  %540 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.peekBits__anon_18665(ptr sret({ i16, i7, [1 x i8] }) %101, ptr %1, ptr nonnull align 8 %540)
  %541 = getelementptr inbounds { i16, i7, [1 x i8] }, ptr %101, i32 0, i32 0
  %542 = load i16, ptr %541, align 2
  %543 = icmp ne i16 %542, 0
  br i1 %543, label %TryRet20, label %TryCont20

Else17:                                           ; preds = %OverflowOk3
  br label %Block25

Block27:                                          ; preds = %OverflowOk4
  br label %Block26

TryRet20:                                         ; preds = %Then19
  %544 = getelementptr inbounds { i16, i7, [1 x i8] }, ptr %101, i32 0, i32 0
  %545 = load i16, ptr %544, align 2
  %546 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %100, i32 0, i32 1
  store i16 %545, ptr %546, align 2
  %547 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %100, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %100, i64 16, i1 false)
  ret void

TryCont20:                                        ; preds = %Then19
  %548 = getelementptr inbounds { i16, i7, [1 x i8] }, ptr %101, i32 0, i32 1
  %549 = load i7, ptr %548, align 1
  %550 = call i7 @llvm.bitreverse.i7(i7 %549)
  store i7 %550, ptr %99, align 1
  %551 = zext i7 %550 to i16
  call fastcc void @"compress.flate.Decompress.HuffmanDecoder(19,7,7).find"(ptr sret({ i46, i16, [6 x i8] }) %98, ptr %1, ptr nonnull align 8 %106, i16 %551)
  %552 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %98, i32 0, i32 1
  %553 = load i16, ptr %552, align 2
  %554 = icmp ne i16 %553, 0
  br i1 %554, label %TryRet21, label %TryCont21

TryRet21:                                         ; preds = %TryCont20
  %555 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %98, i32 0, i32 1
  %556 = load i16, ptr %555, align 2
  %557 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %97, i32 0, i32 1
  store i16 %556, ptr %557, align 2
  %558 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %97, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %97, i64 16, i1 false)
  ret void

TryCont21:                                        ; preds = %TryCont20
  %559 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %98, i32 0, i32 0
  %560 = load i46, ptr %559, align 8
  store i46 %560, ptr %96, align 8
  %561 = load ptr, ptr %188, align 8
  %562 = lshr i46 %560, 8
  %563 = trunc i46 %562 to i4
  %564 = call fastcc i16 @compress.flate.Decompress.tossBits(ptr %1, ptr nonnull align 8 %561, i4 %563)
  %565 = icmp ne i16 %564, 0
  br i1 %565, label %TryRet22, label %TryCont22

TryRet22:                                         ; preds = %TryCont21
  %566 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %95, i32 0, i32 1
  store i16 %564, ptr %566, align 2
  %567 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %95, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %95, i64 16, i1 false)
  ret void

TryCont22:                                        ; preds = %TryCont21
  %568 = load i64, ptr %102, align 8
  %569 = load ptr, ptr %188, align 8
  %570 = lshr i46 %560, 0
  %571 = trunc i46 %570 to i8
  %572 = zext i8 %571 to i16
  %573 = getelementptr inbounds [316 x i4], ptr %103, i64 0, i64 0
  %574 = insertvalue { ptr, i64 } poison, ptr %573, 0
  %575 = insertvalue { ptr, i64 } %574, i64 316, 1
  %576 = load i64, ptr %102, align 8
  %577 = extractvalue { ptr, i64 } %575, 0
  %578 = extractvalue { ptr, i64 } %575, 1
  call fastcc void @compress.flate.Decompress.dynamicCodeLength(ptr sret({ i64, i16, [6 x i8] }) %94, ptr %1, ptr nonnull align 8 %569, i16 %572, ptr nonnull align 1 %577, i64 %578, i64 %576)
  %579 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %94, i32 0, i32 1
  %580 = load i16, ptr %579, align 2
  %581 = icmp ne i16 %580, 0
  br i1 %581, label %TryRet23, label %TryCont23

TryRet23:                                         ; preds = %TryCont22
  %582 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %94, i32 0, i32 1
  %583 = load i16, ptr %582, align 2
  %584 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %93, i32 0, i32 1
  store i16 %583, ptr %584, align 2
  %585 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %93, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %93, i64 16, i1 false)
  ret void

TryCont23:                                        ; preds = %TryCont22
  %586 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %94, i32 0, i32 0
  %587 = load i64, ptr %586, align 8
  %588 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %568, i64 %587)
  %589 = extractvalue { i64, i1 } %588, 1
  br i1 %589, label %OverflowFail4, label %OverflowOk4

OverflowFail4:                                    ; preds = %TryCont23
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk4:                                      ; preds = %TryCont23
  %590 = extractvalue { i64, i1 } %588, 0
  store i64 %590, ptr %102, align 8
  br label %Block27

Block28:                                          ; preds = %Else18
  %591 = load ptr, ptr %188, align 8
  %592 = getelementptr inbounds %compress.flate.Decompress, ptr %591, i32 0, i32 3
  %593 = getelementptr inbounds i4, ptr %103, i64 0
  %594 = zext i16 %453 to i64
  %595 = icmp ule i64 0, %594
  br i1 %595, label %Then21, label %Else19

OverflowFail5:                                    ; preds = %Block25
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk5:                                      ; preds = %Block25
  %596 = extractvalue { i16, i1 } %532, 0
  %597 = zext i16 %596 to i64
  %598 = icmp ugt i64 %531, %597
  br i1 %598, label %Then20, label %Else18

Then20:                                           ; preds = %OverflowOk5
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @632, i64 16, i1 false)
  ret void

Else18:                                           ; preds = %OverflowOk5
  br label %Block28

Block29:                                          ; preds = %Then21
  %599 = sub nuw i64 %594, 0
  %600 = icmp ule i64 %594, 316
  br i1 %600, label %Then22, label %Else20

Then21:                                           ; preds = %Block28
  br label %Block29

Else19:                                           ; preds = %Block28
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).startGreaterThanEnd"(ptr %1, i64 0, i64 %594)
  unreachable

Block30:                                          ; preds = %Then22
  %601 = icmp ule i64 0, %594
  br i1 %601, label %Then23, label %Else21

Then22:                                           ; preds = %Block29
  br label %Block30

Else20:                                           ; preds = %Block29
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 %594, i64 316)
  unreachable

Block31:                                          ; preds = %Then23
  %602 = insertvalue { ptr, i64 } poison, ptr %593, 0
  %603 = insertvalue { ptr, i64 } %602, i64 %599, 1
  store { ptr, i64 } %603, ptr %92, align 8
  %604 = load { ptr, i64 }, ptr %92, align 8
  %605 = extractvalue { ptr, i64 } %604, 0
  %606 = extractvalue { ptr, i64 } %604, 1
  %607 = call fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(286,15,9).generate"(ptr %1, ptr nonnull align 8 %592, ptr nonnull readonly align 1 %605, i64 %606)
  %608 = icmp ne i16 %607, 0
  br i1 %608, label %TryRet24, label %TryCont24

Then23:                                           ; preds = %Block30
  br label %Block31

Else21:                                           ; preds = %Block30
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 0, i64 %594)
  unreachable

TryRet24:                                         ; preds = %Block31
  %609 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %91, i32 0, i32 1
  store i16 %607, ptr %609, align 2
  %610 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %91, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %91, i64 16, i1 false)
  ret void

TryCont24:                                        ; preds = %Block31
  %611 = load ptr, ptr %188, align 8
  %612 = getelementptr inbounds %compress.flate.Decompress, ptr %611, i32 0, i32 4
  %613 = zext i16 %453 to i64
  %614 = getelementptr inbounds i4, ptr %103, i64 %613
  %615 = zext i16 %467 to i64
  %616 = add nuw i64 %613, %615
  %617 = zext i16 %467 to i64
  %618 = icmp ule i64 %616, 316
  br i1 %618, label %Then24, label %Else22

Block32:                                          ; preds = %Then24
  %619 = icmp ule i64 %613, %616
  br i1 %619, label %Then25, label %Else23

Then24:                                           ; preds = %TryCont24
  br label %Block32

Else22:                                           ; preds = %TryCont24
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 %616, i64 316)
  unreachable

Block33:                                          ; preds = %Then25
  %620 = insertvalue { ptr, i64 } poison, ptr %614, 0
  %621 = insertvalue { ptr, i64 } %620, i64 %617, 1
  store { ptr, i64 } %621, ptr %90, align 8
  %622 = load { ptr, i64 }, ptr %90, align 8
  %623 = extractvalue { ptr, i64 } %622, 0
  %624 = extractvalue { ptr, i64 } %622, 1
  %625 = call fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(30,15,9).generate"(ptr %1, ptr nonnull align 8 %612, ptr nonnull readonly align 1 %623, i64 %624)
  %626 = icmp ne i16 %625, 0
  br i1 %626, label %TryRet25, label %TryCont25

Then25:                                           ; preds = %Block32
  br label %Block33

Else23:                                           ; preds = %Block32
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 %613, i64 %616)
  unreachable

TryRet25:                                         ; preds = %Block33
  %627 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %89, i32 0, i32 1
  store i16 %625, ptr %627, align 2
  %628 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %89, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %89, i64 16, i1 false)
  ret void

TryCont25:                                        ; preds = %Block33
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 @635, i64 4, i1 false)
  br label %Case4

TryRet26:                                         ; preds = %Case2
  %629 = getelementptr inbounds { { ptr, i64 }, i16, [6 x i8] }, ptr %87, i32 0, i32 1
  %630 = load i16, ptr %629, align 2
  %631 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %86, i32 0, i32 1
  store i16 %630, ptr %631, align 2
  %632 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %86, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %86, i64 16, i1 false)
  ret void

TryCont26:                                        ; preds = %Case2
  %633 = getelementptr inbounds { { ptr, i64 }, i16, [6 x i8] }, ptr %87, i32 0, i32 0
  %634 = load { ptr, i64 }, ptr %633, align 8
  store { ptr, i64 } %634, ptr %85, align 8
  %635 = getelementptr inbounds [1 x { ptr, i64 }], ptr %84, i64 0, i64 0
  %636 = load i64, ptr %186, align 8
  %637 = zext i16 %210 to i64
  %638 = call fastcc i64 @Io.Limit.limited(ptr %1, i64 %637)
  %639 = call fastcc i64 @Io.Limit.min(ptr %1, i64 %636, i64 %638)
  store i64 %639, ptr %83, align 8
  %640 = load i64, ptr %83, align 8
  %641 = extractvalue { ptr, i64 } %634, 0
  %642 = extractvalue { ptr, i64 } %634, 1
  %643 = call fastcc { ptr, i64 } @Io.Limit.slice(ptr %1, i64 %640, ptr nonnull align 1 %641, i64 %642)
  store { ptr, i64 } %643, ptr %635, align 8
  %644 = load ptr, ptr %188, align 8
  %645 = getelementptr inbounds %compress.flate.Decompress, ptr %644, i32 0, i32 0
  %646 = load ptr, ptr %645, align 8
  %647 = getelementptr inbounds [1 x { ptr, i64 }], ptr %84, i64 0, i64 0
  %648 = insertvalue { ptr, i64 } poison, ptr %647, 0
  %649 = insertvalue { ptr, i64 } %648, i64 1, 1
  %650 = extractvalue { ptr, i64 } %649, 0
  %651 = extractvalue { ptr, i64 } %649, 1
  call fastcc void @Io.Reader.readVec(ptr sret({ i64, i16, [6 x i8] }) %82, ptr %1, ptr nonnull align 8 %646, ptr nonnull align 8 %650, i64 %651)
  %652 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %82, i32 0, i32 1
  %653 = load i16, ptr %652, align 2
  %654 = icmp ne i16 %653, 0
  br i1 %654, label %TryRet27, label %TryCont27

TryRet27:                                         ; preds = %TryCont26
  %655 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %82, i32 0, i32 1
  %656 = load i16, ptr %655, align 2
  %657 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %81, i32 0, i32 1
  store i16 %656, ptr %657, align 2
  %658 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %81, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %81, i64 16, i1 false)
  ret void

TryCont27:                                        ; preds = %TryCont26
  %659 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %82, i32 0, i32 0
  %660 = load i64, ptr %659, align 8
  store i64 %660, ptr %80, align 8
  %661 = zext i16 %210 to i64
  %662 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %661, i64 %660)
  %663 = extractvalue { i64, i1 } %662, 1
  br i1 %663, label %OverflowFail6, label %OverflowOk6

Block34:                                          ; preds = %IntMaxOk, %Block35
  %664 = load ptr, ptr %187, align 8
  call fastcc void @Io.Writer.advance(ptr %1, ptr nonnull align 8 %664, i64 %660)
  %665 = load i64, ptr %185, align 8
  %666 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %4, i64 %665)
  %667 = extractvalue { i64, i1 } %666, 1
  br i1 %667, label %OverflowFail8, label %OverflowOk8

OverflowFail6:                                    ; preds = %TryCont27
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk6:                                      ; preds = %TryCont27
  %668 = extractvalue { i64, i1 } %662, 0
  %669 = icmp eq i64 %668, 0
  br i1 %669, label %Then26, label %Else24

Then26:                                           ; preds = %OverflowOk6
  %670 = load ptr, ptr %188, align 8
  %671 = getelementptr inbounds %compress.flate.Decompress, ptr %670, i32 0, i32 6
  %672 = getelementptr inbounds %compress.flate.Decompress, ptr %2, i32 0, i32 9
  %673 = load i1, ptr %672, align 1
  br i1 %673, label %Then27, label %Else25

Else24:                                           ; preds = %OverflowOk6
  %674 = load ptr, ptr %188, align 8
  %675 = getelementptr inbounds %compress.flate.Decompress, ptr %674, i32 0, i32 6
  %676 = getelementptr inbounds %compress.flate.Decompress.State, ptr %675, i32 0, i32 1
  store i4 2, ptr %676, align 1
  %677 = getelementptr inbounds %compress.flate.Decompress.State, ptr %675, i32 0, i32 0
  %678 = zext i16 %210 to i64
  %679 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %678, i64 %660)
  %680 = extractvalue { i64, i1 } %679, 1
  br i1 %680, label %OverflowFail7, label %OverflowOk7

Block35:                                          ; preds = %Else25, %Then27
  %681 = phi ptr [ @637, %Then27 ], [ @628, %Else25 ]
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %671, ptr align 2 %681, i64 4, i1 false)
  br label %Block34

Then27:                                           ; preds = %Then26
  br label %Block35

Else25:                                           ; preds = %Then26
  br label %Block35

OverflowFail7:                                    ; preds = %Else24
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk7:                                      ; preds = %Else24
  %682 = extractvalue { i64, i1 } %679, 0
  %683 = icmp ule i64 %682, 65535
  br i1 %683, label %IntMaxOk, label %IntMaxFail

IntMaxFail:                                       ; preds = %OverflowOk7
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %1)
  unreachable

IntMaxOk:                                         ; preds = %OverflowOk7
  %684 = trunc i64 %682 to i16
  store i16 %684, ptr %677, align 2
  br label %Block34

OverflowFail8:                                    ; preds = %Block34
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk8:                                      ; preds = %Block34
  %685 = extractvalue { i64, i1 } %666, 0
  %686 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %685, i64 %660)
  %687 = extractvalue { i64, i1 } %686, 1
  br i1 %687, label %OverflowFail9, label %OverflowOk9

OverflowFail9:                                    ; preds = %OverflowOk8
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk9:                                      ; preds = %OverflowOk8
  %688 = extractvalue { i64, i1 } %686, 0
  %689 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %79, i32 0, i32 1
  store i16 0, ptr %689, align 2
  %690 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %79, i32 0, i32 0
  store i64 %688, ptr %690, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %79, i64 16, i1 false)
  ret void

Block36:                                          ; preds = %Else26
  %691 = load ptr, ptr %188, align 8
  %692 = getelementptr inbounds %compress.flate.Decompress, ptr %691, i32 0, i32 6
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %692, ptr align 2 @631, i64 4, i1 false)
  %693 = load i64, ptr %185, align 8
  %694 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %4, i64 %693)
  %695 = extractvalue { i64, i1 } %694, 1
  br i1 %695, label %OverflowFail14, label %OverflowOk14

Loop2:                                            ; preds = %Block37, %Case3
  %696 = load i64, ptr %185, align 8
  %697 = icmp ugt i64 %696, 0
  br i1 %697, label %Then28, label %Else26

Block37:                                          ; preds = %Block38
  br label %Loop2

Then28:                                           ; preds = %Loop2
  %698 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.readFixedCode(ptr sret({ i16, i16 }) %78, ptr %1, ptr nonnull align 8 %698)
  %699 = getelementptr inbounds { i16, i16 }, ptr %78, i32 0, i32 1
  %700 = load i16, ptr %699, align 2
  %701 = icmp ne i16 %700, 0
  br i1 %701, label %TryRet28, label %TryCont28

Else26:                                           ; preds = %Loop2
  br label %Block36

Block38:                                          ; preds = %Block39
  br label %Block37

TryRet28:                                         ; preds = %Then28
  %702 = getelementptr inbounds { i16, i16 }, ptr %78, i32 0, i32 1
  %703 = load i16, ptr %702, align 2
  %704 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %77, i32 0, i32 1
  store i16 %703, ptr %704, align 2
  %705 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %77, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %77, i64 16, i1 false)
  ret void

TryCont28:                                        ; preds = %Then28
  %706 = getelementptr inbounds { i16, i16 }, ptr %78, i32 0, i32 0
  %707 = load i16, ptr %706, align 2
  store i16 %707, ptr %76, align 2
  switch i16 %707, label %RangeTest [
    i16 256, label %Case16
  ]

Block39:                                          ; preds = %OverflowOk13, %OverflowOk11
  br label %Block38

Case16:                                           ; preds = %TryCont28
  %708 = load ptr, ptr %188, align 8
  %709 = getelementptr inbounds %compress.flate.Decompress, ptr %708, i32 0, i32 6
  %710 = getelementptr inbounds %compress.flate.Decompress, ptr %2, i32 0, i32 9
  %711 = load i1, ptr %710, align 1
  br i1 %711, label %Then29, label %Else27

Case17:                                           ; preds = %RangeTest
  %712 = load ptr, ptr %187, align 8
  %713 = icmp ule i16 %707, 255
  br i1 %713, label %IntMaxOk1, label %IntMaxFail1

Case18:                                           ; preds = %RangeTest1
  %714 = load ptr, ptr %188, align 8
  %715 = call { i16, i1 } @llvm.usub.with.overflow.i16(i16 %707, i16 257)
  %716 = extractvalue { i16, i1 } %715, 1
  br i1 %716, label %OverflowFail12, label %OverflowOk12

Default3:                                         ; preds = %RangeTest1
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @638, i64 16, i1 false)
  ret void

RangeTest:                                        ; preds = %TryCont28
  %717 = icmp uge i16 %707, 0
  %718 = icmp ule i16 %707, 255
  %719 = and i1 %717, %718
  br i1 %719, label %Case17, label %RangeTest1

RangeTest1:                                       ; preds = %RangeTest
  %720 = icmp uge i16 %707, 257
  %721 = icmp ule i16 %707, 285
  %722 = and i1 %720, %721
  br i1 %722, label %Case18, label %Default3

Block40:                                          ; preds = %Else27, %Then29
  %723 = phi ptr [ @637, %Then29 ], [ @628, %Else27 ]
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %709, ptr align 2 %723, i64 4, i1 false)
  %724 = load i64, ptr %185, align 8
  %725 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %4, i64 %724)
  %726 = extractvalue { i64, i1 } %725, 1
  br i1 %726, label %OverflowFail10, label %OverflowOk10

Then29:                                           ; preds = %Case16
  br label %Block40

Else27:                                           ; preds = %Case16
  br label %Block40

OverflowFail10:                                   ; preds = %Block40
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk10:                                     ; preds = %Block40
  %727 = extractvalue { i64, i1 } %725, 0
  %728 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %75, i32 0, i32 1
  store i16 0, ptr %728, align 2
  %729 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %75, i32 0, i32 0
  store i64 %727, ptr %729, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %75, i64 16, i1 false)
  ret void

IntMaxFail1:                                      ; preds = %Case17
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %1)
  unreachable

IntMaxOk1:                                        ; preds = %Case17
  %730 = trunc i16 %707 to i8
  %731 = call fastcc i16 @Io.Writer.writeBytePreserve(ptr %1, ptr nonnull align 8 %712, i64 32768, i8 %730)
  %732 = icmp ne i16 %731, 0
  br i1 %732, label %TryRet29, label %TryCont29

TryRet29:                                         ; preds = %IntMaxOk1
  %733 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %74, i32 0, i32 1
  store i16 %731, ptr %733, align 2
  %734 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %74, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %74, i64 16, i1 false)
  ret void

TryCont29:                                        ; preds = %IntMaxOk1
  %735 = load i64, ptr %185, align 8
  %736 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %735, i64 1)
  %737 = extractvalue { i64, i1 } %736, 1
  br i1 %737, label %OverflowFail11, label %OverflowOk11

OverflowFail11:                                   ; preds = %TryCont29
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk11:                                     ; preds = %TryCont29
  %738 = extractvalue { i64, i1 } %736, 0
  store i64 %738, ptr %185, align 8
  br label %Block39

OverflowFail12:                                   ; preds = %Case18
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk12:                                     ; preds = %Case18
  %739 = extractvalue { i16, i1 } %715, 0
  %740 = icmp ule i16 %739, 255
  br i1 %740, label %IntMaxOk2, label %IntMaxFail2

IntMaxFail2:                                      ; preds = %OverflowOk12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %1)
  unreachable

IntMaxOk2:                                        ; preds = %OverflowOk12
  %741 = trunc i16 %739 to i8
  call fastcc void @compress.flate.Decompress.decodeLength(ptr sret({ i16, i16 }) %73, ptr %1, ptr nonnull align 8 %714, i8 %741)
  %742 = getelementptr inbounds { i16, i16 }, ptr %73, i32 0, i32 1
  %743 = load i16, ptr %742, align 2
  %744 = icmp ne i16 %743, 0
  br i1 %744, label %TryRet30, label %TryCont30

TryRet30:                                         ; preds = %IntMaxOk2
  %745 = getelementptr inbounds { i16, i16 }, ptr %73, i32 0, i32 1
  %746 = load i16, ptr %745, align 2
  %747 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %72, i32 0, i32 1
  store i16 %746, ptr %747, align 2
  %748 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %72, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %72, i64 16, i1 false)
  ret void

TryCont30:                                        ; preds = %IntMaxOk2
  %749 = getelementptr inbounds { i16, i16 }, ptr %73, i32 0, i32 0
  %750 = load i16, ptr %749, align 2
  store i16 %750, ptr %71, align 2
  %751 = load ptr, ptr %188, align 8
  %752 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.takeBits__anon_18541(ptr sret({ i16, i5, [1 x i8] }) %70, ptr %1, ptr nonnull align 8 %752)
  %753 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %70, i32 0, i32 0
  %754 = load i16, ptr %753, align 2
  %755 = icmp ne i16 %754, 0
  br i1 %755, label %TryRet31, label %TryCont31

TryRet31:                                         ; preds = %TryCont30
  %756 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %70, i32 0, i32 0
  %757 = load i16, ptr %756, align 2
  %758 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %69, i32 0, i32 1
  store i16 %757, ptr %758, align 2
  %759 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %69, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %69, i64 16, i1 false)
  ret void

TryCont31:                                        ; preds = %TryCont30
  %760 = getelementptr inbounds { i16, i5, [1 x i8] }, ptr %70, i32 0, i32 1
  %761 = load i5, ptr %760, align 1
  %762 = call i5 @llvm.bitreverse.i5(i5 %761)
  %763 = zext i5 %762 to i8
  call fastcc void @compress.flate.Decompress.decodeDistance(ptr sret({ i16, i16 }) %68, ptr %1, ptr nonnull align 8 %751, i8 %763)
  %764 = getelementptr inbounds { i16, i16 }, ptr %68, i32 0, i32 1
  %765 = load i16, ptr %764, align 2
  %766 = icmp ne i16 %765, 0
  br i1 %766, label %TryRet32, label %TryCont32

TryRet32:                                         ; preds = %TryCont31
  %767 = getelementptr inbounds { i16, i16 }, ptr %68, i32 0, i32 1
  %768 = load i16, ptr %767, align 2
  %769 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %67, i32 0, i32 1
  store i16 %768, ptr %769, align 2
  %770 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %67, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %67, i64 16, i1 false)
  ret void

TryCont32:                                        ; preds = %TryCont31
  %771 = getelementptr inbounds { i16, i16 }, ptr %68, i32 0, i32 0
  %772 = load i16, ptr %771, align 2
  store i16 %772, ptr %66, align 2
  %773 = call fastcc i16 @compress.flate.Decompress.writeMatch(ptr %1, ptr nonnull align 8 %3, i16 %750, i16 %772)
  %774 = icmp ne i16 %773, 0
  br i1 %774, label %TryRet33, label %TryCont33

TryRet33:                                         ; preds = %TryCont32
  %775 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %65, i32 0, i32 1
  store i16 %773, ptr %775, align 2
  %776 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %65, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %65, i64 16, i1 false)
  ret void

TryCont33:                                        ; preds = %TryCont32
  %777 = load i64, ptr %185, align 8
  %778 = zext i16 %750 to i64
  %779 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %777, i64 %778)
  %780 = extractvalue { i64, i1 } %779, 1
  br i1 %780, label %OverflowFail13, label %OverflowOk13

OverflowFail13:                                   ; preds = %TryCont33
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk13:                                     ; preds = %TryCont33
  %781 = extractvalue { i64, i1 } %779, 0
  store i64 %781, ptr %185, align 8
  br label %Block39

OverflowFail14:                                   ; preds = %Block36
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk14:                                     ; preds = %Block36
  %782 = extractvalue { i64, i1 } %694, 0
  %783 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %64, i32 0, i32 1
  store i16 0, ptr %783, align 2
  %784 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %64, i32 0, i32 0
  store i64 %782, ptr %784, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %64, i64 16, i1 false)
  ret void

TryRet34:                                         ; preds = %Case4
  %785 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %62, i32 0, i32 1
  %786 = load i16, ptr %785, align 2
  %787 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %61, i32 0, i32 1
  store i16 %786, ptr %787, align 2
  %788 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %61, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %61, i64 16, i1 false)
  ret void

TryCont34:                                        ; preds = %Case4
  %789 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %62, i32 0, i32 0
  %790 = load i46, ptr %789, align 8
  store i46 %790, ptr %63, align 8
  %791 = load i64, ptr %63, align 8
  %792 = trunc i64 %791 to i46
  %793 = lshr i46 %792, 12
  %794 = trunc i46 %793 to i2
  %795 = icmp uge i2 %794, 0
  %796 = icmp ule i2 %794, -2
  %797 = and i1 %795, %796
  br i1 %797, label %Then30, label %Default4

Case19:                                           ; preds = %Then33, %Then30
  %798 = load i64, ptr %185, align 8
  %799 = icmp ne i64 %798, 0
  br i1 %799, label %Then31, label %Else28

Case20:                                           ; preds = %Then33, %Then30
  %800 = load ptr, ptr %188, align 8
  %801 = load i64, ptr %63, align 8
  %802 = trunc i64 %801 to i46
  %803 = lshr i46 %802, 0
  %804 = trunc i46 %803 to i8
  call fastcc void @compress.flate.Decompress.decodeLength(ptr sret({ i16, i16 }) %56, ptr %1, ptr nonnull align 8 %800, i8 %804)
  %805 = getelementptr inbounds { i16, i16 }, ptr %56, i32 0, i32 1
  %806 = load i16, ptr %805, align 2
  %807 = icmp ne i16 %806, 0
  br i1 %807, label %TryRet37, label %TryCont37

Case21:                                           ; preds = %Then33, %Then30
  %808 = load ptr, ptr %188, align 8
  %809 = getelementptr inbounds %compress.flate.Decompress, ptr %808, i32 0, i32 6
  %810 = getelementptr inbounds %compress.flate.Decompress, ptr %2, i32 0, i32 9
  %811 = load i1, ptr %810, align 1
  br i1 %811, label %Then36, label %Else31

Default4:                                         ; preds = %Block41, %TryCont34
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Then30:                                           ; preds = %TryCont34
  %812 = sub nuw i2 %794, 0
  %813 = zext i2 %812 to i64
  %814 = getelementptr inbounds ptr, ptr @__jmptab_1111, i64 %813
  %815 = load ptr, ptr %814, align 8
  indirectbr ptr %815, [label %Case19, label %Case20, label %Case21]

Then31:                                           ; preds = %Case19
  %816 = load i64, ptr %185, align 8
  %817 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %816, i64 1)
  %818 = extractvalue { i64, i1 } %817, 1
  br i1 %818, label %OverflowFail15, label %OverflowOk15

Else28:                                           ; preds = %Case19
  %819 = load ptr, ptr %188, align 8
  %820 = getelementptr inbounds %compress.flate.Decompress, ptr %819, i32 0, i32 6
  %821 = getelementptr inbounds %compress.flate.Decompress.State, ptr %820, i32 0, i32 1
  store i4 5, ptr %821, align 1
  %822 = getelementptr inbounds %compress.flate.Decompress.State, ptr %820, i32 0, i32 0
  %823 = load i64, ptr %63, align 8
  %824 = trunc i64 %823 to i46
  %825 = lshr i46 %824, 0
  %826 = trunc i46 %825 to i8
  store i8 %826, ptr %822, align 1
  %827 = load i64, ptr %185, align 8
  %828 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %4, i64 %827)
  %829 = extractvalue { i64, i1 } %828, 1
  br i1 %829, label %OverflowFail16, label %OverflowOk16

OverflowFail15:                                   ; preds = %Then31
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk15:                                     ; preds = %Then31
  %830 = extractvalue { i64, i1 } %817, 0
  store i64 %830, ptr %185, align 8
  %831 = load ptr, ptr %187, align 8
  %832 = load i64, ptr %63, align 8
  %833 = trunc i64 %832 to i46
  %834 = lshr i46 %833, 0
  %835 = trunc i46 %834 to i8
  %836 = call fastcc i16 @Io.Writer.writeBytePreserve(ptr %1, ptr nonnull align 8 %831, i64 32768, i8 %835)
  %837 = icmp ne i16 %836, 0
  br i1 %837, label %TryRet35, label %TryCont35

TryRet35:                                         ; preds = %OverflowOk15
  %838 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %60, i32 0, i32 1
  store i16 %836, ptr %838, align 2
  %839 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %60, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %60, i64 16, i1 false)
  ret void

TryCont35:                                        ; preds = %OverflowOk15
  %840 = load ptr, ptr %188, align 8
  %841 = load ptr, ptr %188, align 8
  %842 = getelementptr inbounds %compress.flate.Decompress, ptr %841, i32 0, i32 3
  call fastcc void @compress.flate.Decompress.decodeSymbol__anon_18911(ptr sret({ i46, i16, [6 x i8] }) %59, ptr %1, ptr nonnull align 8 %840, ptr nonnull align 8 %842)
  %843 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %59, i32 0, i32 1
  %844 = load i16, ptr %843, align 2
  %845 = icmp ne i16 %844, 0
  br i1 %845, label %TryRet36, label %TryCont36

TryRet36:                                         ; preds = %TryCont35
  %846 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %59, i32 0, i32 1
  %847 = load i16, ptr %846, align 2
  %848 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %58, i32 0, i32 1
  store i16 %847, ptr %848, align 2
  %849 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %58, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %58, i64 16, i1 false)
  ret void

TryCont36:                                        ; preds = %TryCont35
  %850 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %59, i32 0, i32 0
  %851 = load i46, ptr %850, align 8
  store i46 %851, ptr %63, align 8
  %852 = load i64, ptr %63, align 8
  %853 = trunc i64 %852 to i46
  %854 = lshr i46 %853, 12
  %855 = trunc i46 %854 to i2
  %856 = call fastcc i1 @__zig_is_named_enum_value_compress.flate.Decompress.Symbol.Kind(i2 %855)
  br i1 %856, label %Then32, label %Else29

Block41:                                          ; preds = %Then32
  %857 = icmp uge i2 %855, 0
  %858 = icmp ule i2 %855, -2
  %859 = and i1 %857, %858
  br i1 %859, label %Then33, label %Default4

Then32:                                           ; preds = %TryCont36
  br label %Block41

Else29:                                           ; preds = %TryCont36
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Then33:                                           ; preds = %Block41
  %860 = sub nuw i2 %855, 0
  %861 = zext i2 %860 to i64
  %862 = getelementptr inbounds ptr, ptr @__jmptab_1111, i64 %861
  %863 = load ptr, ptr %862, align 8
  indirectbr ptr %863, [label %Case19, label %Case20, label %Case21]

OverflowFail16:                                   ; preds = %Else28
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk16:                                     ; preds = %Else28
  %864 = extractvalue { i64, i1 } %828, 0
  %865 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %57, i32 0, i32 1
  store i16 0, ptr %865, align 2
  %866 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %57, i32 0, i32 0
  store i64 %864, ptr %866, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %57, i64 16, i1 false)
  ret void

TryRet37:                                         ; preds = %Case20
  %867 = getelementptr inbounds { i16, i16 }, ptr %56, i32 0, i32 1
  %868 = load i16, ptr %867, align 2
  %869 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %55, i32 0, i32 1
  store i16 %868, ptr %869, align 2
  %870 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %55, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %55, i64 16, i1 false)
  ret void

TryCont37:                                        ; preds = %Case20
  %871 = getelementptr inbounds { i16, i16 }, ptr %56, i32 0, i32 0
  %872 = load i16, ptr %871, align 2
  store i16 %872, ptr %54, align 2
  %873 = getelementptr inbounds { i16, i4, [1 x i8] }, ptr %53, i64 0, i32 0
  store i16 %872, ptr %873, align 2
  %874 = getelementptr inbounds { i16, i4, [1 x i8] }, ptr %53, i64 0, i32 1
  store i4 6, ptr %874, align 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 %53, i64 4, i1 false)
  %875 = getelementptr inbounds %compress.flate.Decompress.State, ptr %53, i32 0, i32 1
  %876 = load i4, ptr %875, align 1
  %877 = call fastcc i1 @"__zig_is_named_enum_value_@typeInfo(compress.flate.Decompress.State).@\22union\22.tag_type.?"(i4 %876)
  br i1 %877, label %Then34, label %Else30

Block42:                                          ; preds = %Then34
  %878 = icmp uge i4 %876, 0
  %879 = icmp ule i4 %876, -8
  %880 = and i1 %878, %879
  br i1 %880, label %Then35, label %Default

Then34:                                           ; preds = %TryCont37
  br label %Block42

Else30:                                           ; preds = %TryCont37
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Then35:                                           ; preds = %Block42
  %881 = sub nuw i4 %876, 0
  %882 = zext i4 %881 to i64
  %883 = getelementptr inbounds ptr, ptr @__jmptab_1412, i64 %882
  %884 = load ptr, ptr %883, align 8
  indirectbr ptr %884, [label %Case, label %Case1, label %Case2, label %Case3, label %Case4, label %Case5, label %Case6, label %Case7, label %Case8]

Block43:                                          ; preds = %Else31, %Then36
  %885 = phi ptr [ @637, %Then36 ], [ @628, %Else31 ]
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %809, ptr align 2 %885, i64 4, i1 false)
  %886 = getelementptr inbounds %compress.flate.Decompress, ptr %2, i32 0, i32 6
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %52, ptr align 2 %886, i64 4, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 %52, i64 4, i1 false)
  %887 = getelementptr inbounds %compress.flate.Decompress.State, ptr %52, i32 0, i32 1
  %888 = load i4, ptr %887, align 1
  %889 = call fastcc i1 @"__zig_is_named_enum_value_@typeInfo(compress.flate.Decompress.State).@\22union\22.tag_type.?"(i4 %888)
  br i1 %889, label %Then37, label %Else32

Then36:                                           ; preds = %Case21
  br label %Block43

Else31:                                           ; preds = %Case21
  br label %Block43

Block44:                                          ; preds = %Then37
  %890 = icmp uge i4 %888, 0
  %891 = icmp ule i4 %888, -8
  %892 = and i1 %890, %891
  br i1 %892, label %Then38, label %Default

Then37:                                           ; preds = %Block43
  br label %Block44

Else32:                                           ; preds = %Block43
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Then38:                                           ; preds = %Block44
  %893 = sub nuw i4 %888, 0
  %894 = zext i4 %893 to i64
  %895 = getelementptr inbounds ptr, ptr @__jmptab_1412, i64 %894
  %896 = load ptr, ptr %895, align 8
  indirectbr ptr %896, [label %Case, label %Case1, label %Case2, label %Case3, label %Case4, label %Case5, label %Case6, label %Case7, label %Case8]

OverflowFail17:                                   ; preds = %Case5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk17:                                     ; preds = %Case5
  %897 = extractvalue { i64, i1 } %226, 0
  store i64 %897, ptr %185, align 8
  %898 = load ptr, ptr %187, align 8
  %899 = call fastcc i16 @Io.Writer.writeBytePreserve(ptr %1, ptr nonnull align 8 %898, i64 32768, i8 %222)
  %900 = icmp ne i16 %899, 0
  br i1 %900, label %TryRet38, label %TryCont38

TryRet38:                                         ; preds = %OverflowOk17
  %901 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %50, i32 0, i32 1
  store i16 %899, ptr %901, align 2
  %902 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %50, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %50, i64 16, i1 false)
  ret void

TryCont38:                                        ; preds = %OverflowOk17
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 @635, i64 4, i1 false)
  br label %Case4

Then39:                                           ; preds = %Case6
  %903 = load i64, ptr %185, align 8
  %904 = zext i16 %229 to i64
  %905 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %903, i64 %904)
  %906 = extractvalue { i64, i1 } %905, 1
  br i1 %906, label %OverflowFail18, label %OverflowOk18

Else33:                                           ; preds = %Case6
  %907 = load ptr, ptr %188, align 8
  %908 = getelementptr inbounds %compress.flate.Decompress, ptr %907, i32 0, i32 6
  %909 = getelementptr inbounds %compress.flate.Decompress.State, ptr %908, i32 0, i32 1
  store i4 6, ptr %909, align 1
  %910 = getelementptr inbounds %compress.flate.Decompress.State, ptr %908, i32 0, i32 0
  store i16 %229, ptr %910, align 2
  %911 = load i64, ptr %185, align 8
  %912 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %4, i64 %911)
  %913 = extractvalue { i64, i1 } %912, 1
  br i1 %913, label %OverflowFail19, label %OverflowOk19

OverflowFail18:                                   ; preds = %Then39
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk18:                                     ; preds = %Then39
  %914 = extractvalue { i64, i1 } %905, 0
  store i64 %914, ptr %185, align 8
  %915 = load ptr, ptr %188, align 8
  %916 = load ptr, ptr %188, align 8
  %917 = getelementptr inbounds %compress.flate.Decompress, ptr %916, i32 0, i32 4
  call fastcc void @compress.flate.Decompress.decodeSymbol__anon_18944(ptr sret({ i46, i16, [6 x i8] }) %48, ptr %1, ptr nonnull align 8 %915, ptr nonnull align 8 %917)
  %918 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %48, i32 0, i32 1
  %919 = load i16, ptr %918, align 2
  %920 = icmp ne i16 %919, 0
  br i1 %920, label %TryRet39, label %TryCont39

TryRet39:                                         ; preds = %OverflowOk18
  %921 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %48, i32 0, i32 1
  %922 = load i16, ptr %921, align 2
  %923 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %47, i32 0, i32 1
  store i16 %922, ptr %923, align 2
  %924 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %47, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %47, i64 16, i1 false)
  ret void

TryCont39:                                        ; preds = %OverflowOk18
  %925 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %48, i32 0, i32 0
  %926 = load i46, ptr %925, align 8
  store i46 %926, ptr %46, align 8
  %927 = load ptr, ptr %188, align 8
  %928 = lshr i46 %926, 0
  %929 = trunc i46 %928 to i8
  call fastcc void @compress.flate.Decompress.decodeDistance(ptr sret({ i16, i16 }) %45, ptr %1, ptr nonnull align 8 %927, i8 %929)
  %930 = getelementptr inbounds { i16, i16 }, ptr %45, i32 0, i32 1
  %931 = load i16, ptr %930, align 2
  %932 = icmp ne i16 %931, 0
  br i1 %932, label %TryRet40, label %TryCont40

TryRet40:                                         ; preds = %TryCont39
  %933 = getelementptr inbounds { i16, i16 }, ptr %45, i32 0, i32 1
  %934 = load i16, ptr %933, align 2
  %935 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %44, i32 0, i32 1
  store i16 %934, ptr %935, align 2
  %936 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %44, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %44, i64 16, i1 false)
  ret void

TryCont40:                                        ; preds = %TryCont39
  %937 = getelementptr inbounds { i16, i16 }, ptr %45, i32 0, i32 0
  %938 = load i16, ptr %937, align 2
  store i16 %938, ptr %43, align 2
  %939 = call fastcc i16 @compress.flate.Decompress.writeMatch(ptr %1, ptr nonnull align 8 %3, i16 %229, i16 %938)
  %940 = icmp ne i16 %939, 0
  br i1 %940, label %TryRet41, label %TryCont41

TryRet41:                                         ; preds = %TryCont40
  %941 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %42, i32 0, i32 1
  store i16 %939, ptr %941, align 2
  %942 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %42, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %42, i64 16, i1 false)
  ret void

TryCont41:                                        ; preds = %TryCont40
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %182, ptr align 2 @635, i64 4, i1 false)
  br label %Case4

OverflowFail19:                                   ; preds = %Else33
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk19:                                     ; preds = %Else33
  %943 = extractvalue { i64, i1 } %912, 0
  %944 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %41, i32 0, i32 1
  store i16 0, ptr %944, align 2
  %945 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %41, i32 0, i32 0
  store i64 %943, ptr %945, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %41, i64 16, i1 false)
  ret void

Block45:                                          ; preds = %TryCont47, %TryCont45, %Case24
  %946 = load ptr, ptr %188, align 8
  %947 = getelementptr inbounds %compress.flate.Decompress, ptr %946, i32 0, i32 6
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %947, ptr align 2 @639, i64 4, i1 false)
  %948 = load i64, ptr %185, align 8
  %949 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %4, i64 %948)
  %950 = extractvalue { i64, i1 } %949, 1
  br i1 %950, label %OverflowFail20, label %OverflowOk20

Case22:                                           ; preds = %Case7
  %951 = getelementptr inbounds %compress.flate.Container.Metadata, ptr %234, i32 0, i32 0
  store ptr %951, ptr %40, align 8
  %952 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.alignBitsDiscarding(ptr %1, ptr nonnull align 8 %952)
  %953 = getelementptr inbounds %compress.flate.Container.Metadata__struct_6008, ptr %951, i32 0, i32 0
  %954 = load ptr, ptr %184, align 8
  store ptr %954, ptr %39, align 8
  store i1 true, ptr %38, align 1
  store ptr %954, ptr %37, align 8
  store i16 4, ptr %36, align 2
  %955 = load ptr, ptr %37, align 8
  call fastcc void @Io.Reader.takeArray__anon_18964(ptr sret({ ptr, i16, [6 x i8] }) %35, ptr %1, ptr nonnull align 8 %955)
  %956 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %35, i32 0, i32 1
  %957 = load i16, ptr %956, align 2
  %958 = icmp ne i16 %957, 0
  br i1 %958, label %TryRet42, label %TryCont42

Case23:                                           ; preds = %Case7
  %959 = getelementptr inbounds %compress.flate.Container.Metadata, ptr %234, i32 0, i32 0
  store ptr %959, ptr %17, align 8
  %960 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.alignBitsDiscarding(ptr %1, ptr nonnull align 8 %960)
  %961 = getelementptr inbounds %compress.flate.Container.Metadata__struct_6009, ptr %959, i32 0, i32 0
  %962 = load ptr, ptr %184, align 8
  store ptr %962, ptr %16, align 8
  store i1 true, ptr %15, align 1
  store ptr %962, ptr %14, align 8
  store i16 4, ptr %13, align 2
  %963 = load ptr, ptr %14, align 8
  call fastcc void @Io.Reader.takeArray__anon_18964(ptr sret({ ptr, i16, [6 x i8] }) %12, ptr %1, ptr nonnull align 8 %963)
  %964 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %12, i32 0, i32 1
  %965 = load i16, ptr %964, align 2
  %966 = icmp ne i16 %965, 0
  br i1 %966, label %TryRet46, label %TryCont46

Case24:                                           ; preds = %Case7
  %967 = load ptr, ptr %188, align 8
  call fastcc void @compress.flate.Decompress.alignBitsPreserving(ptr %1, ptr nonnull align 8 %967)
  br label %Block45

Default5:                                         ; preds = %Case7
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).corruptSwitch"(ptr %1)
  unreachable

Block46:                                          ; preds = %Block47, %TryRet42
  %968 = phi ptr [ %34, %TryRet42 ], [ %30, %Block47 ]
  %969 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %968, i32 0, i32 1
  %970 = load i16, ptr %969, align 2
  %971 = icmp ne i16 %970, 0
  br i1 %971, label %TryRet43, label %TryCont43

TryRet42:                                         ; preds = %Case22
  %972 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %35, i32 0, i32 1
  %973 = load i16, ptr %972, align 2
  %974 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %34, i32 0, i32 1
  store i16 %973, ptr %974, align 2
  %975 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %34, i32 0, i32 0
  br label %Block46

TryCont42:                                        ; preds = %Case22
  %976 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %35, i32 0, i32 0
  %977 = load ptr, ptr %976, align 8
  store ptr %977, ptr %33, align 8
  store i1 true, ptr %32, align 1
  %978 = load i32, ptr %977, align 1
  store i32 %978, ptr %31, align 4
  br label %Block47

Block47:                                          ; preds = %TryCont42
  %979 = phi i32 [ %978, %TryCont42 ]
  %980 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %30, i32 0, i32 1
  store i16 0, ptr %980, align 2
  %981 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %30, i32 0, i32 0
  store i32 %979, ptr %981, align 4
  br label %Block46

TryRet43:                                         ; preds = %Block46
  %982 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %968, i32 0, i32 1
  %983 = load i16, ptr %982, align 2
  %984 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %29, i32 0, i32 1
  store i16 %983, ptr %984, align 2
  %985 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %29, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %29, i64 16, i1 false)
  ret void

TryCont43:                                        ; preds = %Block46
  %986 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %968, i32 0, i32 0
  %987 = load i32, ptr %986, align 4
  store i32 %987, ptr %953, align 4
  %988 = getelementptr inbounds %compress.flate.Container.Metadata__struct_6008, ptr %951, i32 0, i32 1
  %989 = load ptr, ptr %184, align 8
  store ptr %989, ptr %28, align 8
  store i1 true, ptr %27, align 1
  store ptr %989, ptr %26, align 8
  store i16 4, ptr %25, align 2
  %990 = load ptr, ptr %26, align 8
  call fastcc void @Io.Reader.takeArray__anon_18964(ptr sret({ ptr, i16, [6 x i8] }) %24, ptr %1, ptr nonnull align 8 %990)
  %991 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %24, i32 0, i32 1
  %992 = load i16, ptr %991, align 2
  %993 = icmp ne i16 %992, 0
  br i1 %993, label %TryRet44, label %TryCont44

Block48:                                          ; preds = %Block49, %TryRet44
  %994 = phi ptr [ %23, %TryRet44 ], [ %19, %Block49 ]
  %995 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %994, i32 0, i32 1
  %996 = load i16, ptr %995, align 2
  %997 = icmp ne i16 %996, 0
  br i1 %997, label %TryRet45, label %TryCont45

TryRet44:                                         ; preds = %TryCont43
  %998 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %24, i32 0, i32 1
  %999 = load i16, ptr %998, align 2
  %1000 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %23, i32 0, i32 1
  store i16 %999, ptr %1000, align 2
  %1001 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %23, i32 0, i32 0
  br label %Block48

TryCont44:                                        ; preds = %TryCont43
  %1002 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %24, i32 0, i32 0
  %1003 = load ptr, ptr %1002, align 8
  store ptr %1003, ptr %22, align 8
  store i1 true, ptr %21, align 1
  %1004 = load i32, ptr %1003, align 1
  store i32 %1004, ptr %20, align 4
  br label %Block49

Block49:                                          ; preds = %TryCont44
  %1005 = phi i32 [ %1004, %TryCont44 ]
  %1006 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %19, i32 0, i32 1
  store i16 0, ptr %1006, align 2
  %1007 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %19, i32 0, i32 0
  store i32 %1005, ptr %1007, align 4
  br label %Block48

TryRet45:                                         ; preds = %Block48
  %1008 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %994, i32 0, i32 1
  %1009 = load i16, ptr %1008, align 2
  %1010 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %18, i32 0, i32 1
  store i16 %1009, ptr %1010, align 2
  %1011 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %18, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %18, i64 16, i1 false)
  ret void

TryCont45:                                        ; preds = %Block48
  %1012 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %994, i32 0, i32 0
  %1013 = load i32, ptr %1012, align 4
  store i32 %1013, ptr %988, align 4
  br label %Block45

Block50:                                          ; preds = %Block51, %TryRet46
  %1014 = phi ptr [ %11, %TryRet46 ], [ %7, %Block51 ]
  %1015 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %1014, i32 0, i32 1
  %1016 = load i16, ptr %1015, align 2
  %1017 = icmp ne i16 %1016, 0
  br i1 %1017, label %TryRet47, label %TryCont47

TryRet46:                                         ; preds = %Case23
  %1018 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %12, i32 0, i32 1
  %1019 = load i16, ptr %1018, align 2
  %1020 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %11, i32 0, i32 1
  store i16 %1019, ptr %1020, align 2
  %1021 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %11, i32 0, i32 0
  br label %Block50

TryCont46:                                        ; preds = %Case23
  %1022 = getelementptr inbounds { ptr, i16, [6 x i8] }, ptr %12, i32 0, i32 0
  %1023 = load ptr, ptr %1022, align 8
  store ptr %1023, ptr %10, align 8
  store i1 true, ptr %9, align 1
  %1024 = load i32, ptr %1023, align 1
  store i32 %1024, ptr %8, align 4
  br label %Block51

Block51:                                          ; preds = %TryCont46
  %1025 = phi i32 [ %1024, %TryCont46 ]
  %1026 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %7, i32 0, i32 1
  store i16 0, ptr %1026, align 2
  %1027 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %7, i32 0, i32 0
  store i32 %1025, ptr %1027, align 4
  br label %Block50

TryRet47:                                         ; preds = %Block50
  %1028 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %1014, i32 0, i32 1
  %1029 = load i16, ptr %1028, align 2
  %1030 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %6, i32 0, i32 1
  store i16 %1029, ptr %1030, align 2
  %1031 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %6, i32 0, i32 0
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %6, i64 16, i1 false)
  ret void

TryCont47:                                        ; preds = %Block50
  %1032 = getelementptr inbounds { i32, i16, [2 x i8] }, ptr %1014, i32 0, i32 0
  %1033 = load i32, ptr %1032, align 4
  store i32 %1033, ptr %961, align 4
  br label %Block45

OverflowFail20:                                   ; preds = %Block45
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk20:                                     ; preds = %Block45
  %1034 = extractvalue { i64, i1 } %949, 0
  %1035 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %5, i32 0, i32 1
  store i16 0, ptr %1035, align 2
  %1036 = getelementptr inbounds { i64, i16, [6 x i8] }, ptr %5, i32 0, i32 0
  store i64 %1034, ptr %1036, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %5, i64 16, i1 false)
  ret void
}

; Function Attrs: cold nounwind uwtable
declare fastcc void @Io.Writer.unreachableDrain(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: cold nounwind uwtable
declare fastcc i16 @Io.Writer.unreachableRebase(ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBitsEnding__anon_18497(ptr noalias nonnull sret({ i16, i1, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i6, i1 } @llvm.usub.with.overflow.i6(i6, i6) #1

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeVarInt__anon_18507(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBits__anon_18482(ptr noalias nonnull sret({ i16, i1, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeArray__anon_18488(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBitsEnding__anon_18518(ptr noalias nonnull sret({ i16, i2, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBits__anon_18512(ptr noalias nonnull sret({ i16, i2, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBitsEnding__anon_18547(ptr noalias nonnull sret({ i16, i5, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBits__anon_18541(ptr noalias nonnull sret({ i16, i5, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBitsEnding__anon_18560(ptr noalias nonnull sret({ i16, i4, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBits__anon_18554(ptr noalias nonnull sret({ i16, i4, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBitsEnding__anon_18586(ptr noalias nonnull sret({ i16, i3, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBits__anon_18580(ptr noalias nonnull sret({ i16, i3, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
define internal fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(19,7,7).checkCompleteness"(ptr nonnull %0, ptr nonnull readonly align 1 %1, i64 %2) unnamed_addr #0 {
Entry:
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = alloca i4, align 1
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca [8 x i16], align 2
  %10 = alloca { ptr, i64 }, align 8
  %11 = insertvalue { ptr, i64 } poison, ptr %1, 0
  %12 = insertvalue { ptr, i64 } %11, i64 %2, 1
  store { ptr, i64 } %12, ptr %10, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %9, ptr align 2 @605, i64 16, i1 false)
  store i64 0, ptr %8, align 8
  store i64 0, ptr %7, align 8
  %13 = extractvalue { ptr, i64 } %12, 1
  br label %Loop

Block:                                            ; preds = %Else
  %14 = load i64, ptr %8, align 8
  %15 = icmp eq i64 %14, 0
  br i1 %15, label %Then4, label %Else4

Loop:                                             ; preds = %Block1, %Entry
  %16 = load i64, ptr %7, align 8
  %17 = icmp ult i64 %16, %13
  br i1 %17, label %Then, label %Else

Block1:                                           ; preds = %OverflowOk, %Then1
  %18 = add nuw i64 %16, 1
  store i64 %18, ptr %7, align 8
  br label %Loop

Then:                                             ; preds = %Loop
  %19 = extractvalue { ptr, i64 } %12, 0
  %20 = getelementptr inbounds i4, ptr %19, i64 %16
  %21 = load i8, ptr %20, align 1
  %22 = trunc i8 %21 to i4
  store i4 %22, ptr %6, align 1
  %23 = icmp eq i4 %22, 0
  br i1 %23, label %Then1, label %Else1

Else:                                             ; preds = %Loop
  br label %Block

Block2:                                           ; preds = %Else1
  %24 = load i64, ptr %8, align 8
  %25 = zext i4 %22 to i64
  %26 = icmp ugt i64 %25, %24
  br i1 %26, label %Then2, label %Else2

Then1:                                            ; preds = %Then
  br label %Block1

Else1:                                            ; preds = %Then
  br label %Block2

Block3:                                           ; preds = %Else2, %Then2
  %27 = zext i4 %22 to i64
  %28 = icmp ult i64 %27, 8
  br i1 %28, label %Then3, label %Else3

Then2:                                            ; preds = %Block2
  %29 = zext i4 %22 to i64
  store i64 %29, ptr %8, align 8
  br label %Block3

Else2:                                            ; preds = %Block2
  br label %Block3

Block4:                                           ; preds = %Then3
  %30 = getelementptr inbounds [8 x i16], ptr %9, i64 0, i64 %27
  %31 = load i16, ptr %30, align 2
  %32 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %31, i16 1)
  %33 = extractvalue { i16, i1 } %32, 1
  br i1 %33, label %OverflowFail, label %OverflowOk

Then3:                                            ; preds = %Block3
  br label %Block4

Else3:                                            ; preds = %Block3
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %27, i64 8)
  unreachable

OverflowFail:                                     ; preds = %Block4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk:                                       ; preds = %Block4
  %34 = extractvalue { i16, i1 } %32, 0
  store i16 %34, ptr %30, align 2
  br label %Block1

Block5:                                           ; preds = %Else4
  store i64 1, ptr %5, align 8
  store i64 0, ptr %4, align 8
  br label %Loop1

Then4:                                            ; preds = %Block
  ret i16 0

Else4:                                            ; preds = %Block
  br label %Block5

Block6:                                           ; preds = %Else5
  %35 = load i64, ptr %5, align 8
  %36 = icmp ugt i64 %35, 0
  br i1 %36, label %Then9, label %Else9

Loop1:                                            ; preds = %Block7, %Block5
  %37 = load i64, ptr %4, align 8
  %38 = icmp ult i64 %37, 7
  br i1 %38, label %Then5, label %Else5

Block7:                                           ; preds = %OverflowOk2
  %39 = add nuw i64 %37, 1
  store i64 %39, ptr %4, align 8
  br label %Loop1

Then5:                                            ; preds = %Loop1
  %40 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 1, i64 %37)
  %41 = extractvalue { i64, i1 } %40, 1
  br i1 %41, label %OverflowFail1, label %OverflowOk1

Else5:                                            ; preds = %Loop1
  br label %Block6

OverflowFail1:                                    ; preds = %Then5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk1:                                      ; preds = %Then5
  %42 = extractvalue { i64, i1 } %40, 0
  store i64 %42, ptr %3, align 8
  %43 = load i64, ptr %5, align 8
  %44 = zext i6 1 to i64
  %45 = shl i64 %43, %44
  store i64 %45, ptr %5, align 8
  %46 = icmp ult i64 %42, 8
  br i1 %46, label %Then6, label %Else6

Block8:                                           ; preds = %Else7
  %47 = load i64, ptr %5, align 8
  %48 = icmp ult i64 %42, 8
  br i1 %48, label %Then8, label %Else8

Block9:                                           ; preds = %Then6
  %49 = getelementptr inbounds [8 x i16], ptr %9, i64 0, i64 %42
  %50 = load i16, ptr %49, align 2
  %51 = load i64, ptr %5, align 8
  %52 = zext i16 %50 to i64
  %53 = icmp ugt i64 %52, %51
  br i1 %53, label %Then7, label %Else7

Then6:                                            ; preds = %OverflowOk1
  br label %Block9

Else6:                                            ; preds = %OverflowOk1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %42, i64 8)
  unreachable

Then7:                                            ; preds = %Block9
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 92

Else7:                                            ; preds = %Block9
  br label %Block8

Block10:                                          ; preds = %Then8
  %54 = getelementptr inbounds [8 x i16], ptr %9, i64 0, i64 %42
  %55 = load i16, ptr %54, align 2
  %56 = zext i16 %55 to i64
  %57 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %47, i64 %56)
  %58 = extractvalue { i64, i1 } %57, 1
  br i1 %58, label %OverflowFail2, label %OverflowOk2

Then8:                                            ; preds = %Block8
  br label %Block10

Else8:                                            ; preds = %Block8
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %42, i64 8)
  unreachable

OverflowFail2:                                    ; preds = %Block10
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk2:                                      ; preds = %Block10
  %59 = extractvalue { i64, i1 } %57, 0
  store i64 %59, ptr %5, align 8
  br label %Block7

Block11:                                          ; preds = %Else9
  ret i16 0

Then9:                                            ; preds = %Block6
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 93

Else9:                                            ; preds = %Block6
  br label %Block11
}

; Function Attrs: nounwind uwtable
define internal fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(19,7,7).generate"(ptr nonnull %0, ptr nonnull align 8 %1, ptr nonnull readonly align 1 %2, i64 %3) unnamed_addr #0 {
Entry:
  %4 = alloca i16, align 2
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i16, align 2
  %10 = alloca i16, align 2
  %11 = alloca i64, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca i64, align 8
  %15 = alloca i16, align 2
  %16 = alloca i16, align 2
  %17 = alloca i64, align 8
  %18 = alloca i64, align 8
  %19 = alloca i4, align 1
  %20 = alloca i64, align 8
  %21 = alloca i64, align 8
  %22 = alloca ptr, align 8
  %23 = alloca { ptr, i64 }, align 8
  %24 = alloca ptr, align 8
  %25 = insertvalue { ptr, i64 } poison, ptr %2, 0
  %26 = insertvalue { ptr, i64 } %25, i64 %3, 1
  store ptr %1, ptr %24, align 8
  store { ptr, i64 } %26, ptr %23, align 8
  store ptr %1, ptr %22, align 8
  %27 = extractvalue { ptr, i64 } %26, 0
  %28 = extractvalue { ptr, i64 } %26, 1
  %29 = call fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(19,7,7).checkCompleteness"(ptr %0, ptr nonnull readonly align 1 %27, i64 %28)
  %30 = icmp ne i16 %29, 0
  br i1 %30, label %TryRet, label %TryCont

TryRet:                                           ; preds = %Entry
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 %29

TryCont:                                          ; preds = %Entry
  store i64 0, ptr %21, align 8
  br label %Loop

Block:                                            ; preds = %Else
  %31 = load ptr, ptr %22, align 8
  %32 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %31, i32 0, i32 0
  %33 = getelementptr inbounds [19 x i46], ptr %32, i64 0, i64 0
  %34 = insertvalue { ptr, i64 } poison, ptr %33, 0
  %35 = insertvalue { ptr, i64 } %34, i64 19, 1
  %36 = extractvalue { ptr, i64 } %35, 0
  %37 = extractvalue { ptr, i64 } %35, 1
  call fastcc void @sort.heap__anon_18649(ptr %0, ptr nonnull align 8 %36, i64 %37)
  store i64 0, ptr %18, align 8
  br label %Loop1

Loop:                                             ; preds = %Block1, %TryCont
  %38 = load i64, ptr %21, align 8
  %39 = icmp ult i64 %38, 19
  br i1 %39, label %Then, label %Else

Block1:                                           ; preds = %Block5
  %40 = add nuw i64 %38, 1
  store i64 %40, ptr %21, align 8
  br label %Loop

Then:                                             ; preds = %Loop
  store i64 %38, ptr %20, align 8
  %41 = extractvalue { ptr, i64 } %26, 1
  %42 = icmp ult i64 %38, %41
  br i1 %42, label %Then1, label %Else1

Else:                                             ; preds = %Loop
  br label %Block

Block2:                                           ; preds = %Block3, %Else1
  %43 = phi i4 [ %52, %Block3 ], [ 0, %Else1 ]
  store i4 %43, ptr %19, align 1
  %44 = load ptr, ptr %22, align 8
  %45 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %44, i32 0, i32 0
  %46 = icmp ult i64 %38, 19
  br i1 %46, label %Then3, label %Else3

Then1:                                            ; preds = %Then
  %47 = extractvalue { ptr, i64 } %26, 1
  %48 = icmp ult i64 %38, %47
  br i1 %48, label %Then2, label %Else2

Else1:                                            ; preds = %Then
  br label %Block2

Block3:                                           ; preds = %Then2
  %49 = extractvalue { ptr, i64 } %26, 0
  %50 = getelementptr inbounds i4, ptr %49, i64 %38
  %51 = load i8, ptr %50, align 1
  %52 = trunc i8 %51 to i4
  br label %Block2

Then2:                                            ; preds = %Then1
  br label %Block3

Else2:                                            ; preds = %Then1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %38, i64 %47)
  unreachable

Block4:                                           ; preds = %Then3
  %53 = getelementptr inbounds [19 x i46], ptr %45, i64 0, i64 %38
  %54 = icmp ult i64 %38, 256
  br i1 %54, label %Then4, label %Else4

Then3:                                            ; preds = %Block2
  br label %Block4

Else3:                                            ; preds = %Block2
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %38, i64 19)
  unreachable

Block5:                                           ; preds = %Block6, %IntMaxOk
  br label %Block1

Then4:                                            ; preds = %Block4
  %55 = load i48, ptr %53, align 8
  %56 = zext i2 -1 to i48
  %57 = shl i48 %56, 12
  %58 = xor i48 %57, -1
  %59 = and i48 %55, %58
  %60 = zext i2 0 to i48
  %61 = shl i48 %60, 12
  %62 = or i48 %61, %59
  store i48 %62, ptr %53, align 8
  %63 = icmp ule i64 %38, 255
  br i1 %63, label %IntMaxOk, label %IntMaxFail

Else4:                                            ; preds = %Block4
  %64 = icmp eq i64 %38, 256
  br i1 %64, label %Then5, label %Else5

IntMaxFail:                                       ; preds = %Then4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk:                                         ; preds = %Then4
  %65 = trunc i64 %38 to i8
  store i8 %65, ptr %53, align 8
  %66 = load i48, ptr %53, align 8
  %67 = zext i4 -1 to i48
  %68 = shl i48 %67, 8
  %69 = xor i48 %68, -1
  %70 = and i48 %66, %69
  %71 = zext i4 %43 to i48
  %72 = shl i48 %71, 8
  %73 = or i48 %72, %70
  store i48 %73, ptr %53, align 8
  %74 = load i48, ptr %53, align 8
  %75 = zext i16 -1 to i48
  %76 = shl i48 %75, 14
  %77 = xor i48 %76, -1
  %78 = and i48 %74, %77
  %79 = zext i16 0 to i48
  %80 = shl i48 %79, 14
  %81 = or i48 %80, %78
  store i48 %81, ptr %53, align 8
  %82 = load i48, ptr %53, align 8
  %83 = zext i16 -1 to i48
  %84 = shl i48 %83, 30
  %85 = xor i48 %84, -1
  %86 = and i48 %82, %85
  %87 = zext i16 0 to i48
  %88 = shl i48 %87, 30
  %89 = or i48 %88, %86
  store i48 %89, ptr %53, align 8
  br label %Block5

Block6:                                           ; preds = %IntMaxOk1, %Then5
  br label %Block5

Then5:                                            ; preds = %Else4
  %90 = load i48, ptr %53, align 8
  %91 = zext i2 -1 to i48
  %92 = shl i48 %91, 12
  %93 = xor i48 %92, -1
  %94 = and i48 %90, %93
  %95 = zext i2 1 to i48
  %96 = shl i48 %95, 12
  %97 = or i48 %96, %94
  store i48 %97, ptr %53, align 8
  store i8 -1, ptr %53, align 8
  %98 = load i48, ptr %53, align 8
  %99 = zext i4 -1 to i48
  %100 = shl i48 %99, 8
  %101 = xor i48 %100, -1
  %102 = and i48 %98, %101
  %103 = zext i4 %43 to i48
  %104 = shl i48 %103, 8
  %105 = or i48 %104, %102
  store i48 %105, ptr %53, align 8
  %106 = load i48, ptr %53, align 8
  %107 = zext i16 -1 to i48
  %108 = shl i48 %107, 14
  %109 = xor i48 %108, -1
  %110 = and i48 %106, %109
  %111 = zext i16 0 to i48
  %112 = shl i48 %111, 14
  %113 = or i48 %112, %110
  store i48 %113, ptr %53, align 8
  %114 = load i48, ptr %53, align 8
  %115 = zext i16 -1 to i48
  %116 = shl i48 %115, 30
  %117 = xor i48 %116, -1
  %118 = and i48 %114, %117
  %119 = zext i16 0 to i48
  %120 = shl i48 %119, 30
  %121 = or i48 %120, %118
  store i48 %121, ptr %53, align 8
  br label %Block6

Else5:                                            ; preds = %Else4
  %122 = load i48, ptr %53, align 8
  %123 = zext i2 -1 to i48
  %124 = shl i48 %123, 12
  %125 = xor i48 %124, -1
  %126 = and i48 %122, %125
  %127 = zext i2 -2 to i48
  %128 = shl i48 %127, 12
  %129 = or i48 %128, %126
  store i48 %129, ptr %53, align 8
  %130 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %38, i64 257)
  %131 = extractvalue { i64, i1 } %130, 1
  br i1 %131, label %OverflowFail, label %OverflowOk

OverflowFail:                                     ; preds = %Else5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk:                                       ; preds = %Else5
  %132 = extractvalue { i64, i1 } %130, 0
  %133 = icmp ule i64 %132, 255
  br i1 %133, label %IntMaxOk1, label %IntMaxFail1

IntMaxFail1:                                      ; preds = %OverflowOk
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk1:                                        ; preds = %OverflowOk
  %134 = trunc i64 %132 to i8
  store i8 %134, ptr %53, align 8
  %135 = load i48, ptr %53, align 8
  %136 = zext i4 -1 to i48
  %137 = shl i48 %136, 8
  %138 = xor i48 %137, -1
  %139 = and i48 %135, %138
  %140 = zext i4 %43 to i48
  %141 = shl i48 %140, 8
  %142 = or i48 %141, %139
  store i48 %142, ptr %53, align 8
  %143 = load i48, ptr %53, align 8
  %144 = zext i16 -1 to i48
  %145 = shl i48 %144, 14
  %146 = xor i48 %145, -1
  %147 = and i48 %143, %146
  %148 = zext i16 0 to i48
  %149 = shl i48 %148, 14
  %150 = or i48 %149, %147
  store i48 %150, ptr %53, align 8
  %151 = load i48, ptr %53, align 8
  %152 = zext i16 -1 to i48
  %153 = shl i48 %152, 30
  %154 = xor i48 %153, -1
  %155 = and i48 %151, %154
  %156 = zext i16 0 to i48
  %157 = shl i48 %156, 30
  %158 = or i48 %157, %155
  store i48 %158, ptr %53, align 8
  br label %Block6

Block7:                                           ; preds = %Else6
  store i16 0, ptr %16, align 2
  store i16 0, ptr %15, align 2
  store i64 0, ptr %14, align 8
  %159 = load ptr, ptr %22, align 8
  %160 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %159, i32 0, i32 0
  br label %Loop2

Loop1:                                            ; preds = %Block8, %Block
  %161 = load i64, ptr %18, align 8
  %162 = icmp ult i64 %161, 128
  br i1 %162, label %Then6, label %Else6

Block8:                                           ; preds = %Block9
  %163 = add nuw i64 %161, 1
  store i64 %163, ptr %18, align 8
  br label %Loop1

Then6:                                            ; preds = %Loop1
  store i64 %161, ptr %17, align 8
  %164 = load ptr, ptr %22, align 8
  %165 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %164, i32 0, i32 1
  %166 = icmp ult i64 %161, 128
  br i1 %166, label %Then7, label %Else7

Else6:                                            ; preds = %Loop1
  br label %Block7

Block9:                                           ; preds = %Then7
  %167 = getelementptr inbounds [128 x i46], ptr %165, i64 0, i64 %161
  store i46 0, ptr %167, align 8
  br label %Block8

Then7:                                            ; preds = %Then6
  br label %Block9

Else7:                                            ; preds = %Then6
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %161, i64 128)
  unreachable

Block10:                                          ; preds = %Then11, %Else8
  ret i16 0

Loop2:                                            ; preds = %Block11, %Block7
  %168 = load i64, ptr %14, align 8
  %169 = icmp ult i64 %168, 19
  br i1 %169, label %Then8, label %Else8

Block11:                                          ; preds = %Block15, %Then9
  %170 = add nuw i64 %168, 1
  store i64 %170, ptr %14, align 8
  br label %Loop2

Then8:                                            ; preds = %Loop2
  %171 = getelementptr inbounds [19 x i46], ptr %160, i64 0, i64 %168
  store ptr %171, ptr %13, align 8
  store ptr %171, ptr %12, align 8
  store i64 %168, ptr %11, align 8
  %172 = load i48, ptr %171, align 8
  %173 = lshr i48 %172, 8
  %174 = trunc i48 %173 to i4
  %175 = icmp eq i4 %174, 0
  br i1 %175, label %Then9, label %Else9

Else8:                                            ; preds = %Loop2
  br label %Block10

Block12:                                          ; preds = %Else9
  %176 = load ptr, ptr %13, align 8
  %177 = load i16, ptr %16, align 2
  %178 = load i48, ptr %176, align 8
  %179 = zext i16 -1 to i48
  %180 = shl i48 %179, 14
  %181 = xor i48 %180, -1
  %182 = and i48 %178, %181
  %183 = zext i16 %177 to i48
  %184 = shl i48 %183, 14
  %185 = or i48 %184, %182
  store i48 %185, ptr %176, align 8
  %186 = load i16, ptr %16, align 2
  %187 = load i48, ptr %171, align 8
  %188 = lshr i48 %187, 8
  %189 = trunc i48 %188 to i4
  %190 = call { i4, i1 } @llvm.usub.with.overflow.i4(i4 7, i4 %189)
  %191 = extractvalue { i4, i1 } %190, 1
  br i1 %191, label %OverflowFail1, label %OverflowOk1

Then9:                                            ; preds = %Then8
  br label %Block11

Else9:                                            ; preds = %Then8
  br label %Block12

OverflowFail1:                                    ; preds = %Block12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk1:                                      ; preds = %Block12
  %192 = extractvalue { i4, i1 } %190, 0
  %193 = zext i4 %192 to i16
  %194 = shl i16 1, %193
  %195 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %186, i16 %194)
  %196 = extractvalue { i16, i1 } %195, 1
  br i1 %196, label %OverflowFail2, label %OverflowOk2

OverflowFail2:                                    ; preds = %OverflowOk1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk2:                                      ; preds = %OverflowOk1
  %197 = extractvalue { i16, i1 } %195, 0
  store i16 %197, ptr %10, align 2
  store i16 %197, ptr %9, align 2
  %198 = icmp ugt i16 %197, 128
  br i1 %198, label %Then10, label %Else10

Block13:                                          ; preds = %Else11
  %199 = load i48, ptr %171, align 8
  %200 = lshr i48 %199, 8
  %201 = trunc i48 %200 to i4
  %202 = icmp ule i4 %201, 7
  br i1 %202, label %Then12, label %Else12

Block14:                                          ; preds = %Else10, %Then10
  %203 = phi i1 [ true, %Then10 ], [ %205, %Else10 ]
  br i1 %203, label %Then11, label %Else11

Then10:                                           ; preds = %OverflowOk2
  br label %Block14

Else10:                                           ; preds = %OverflowOk2
  %204 = load i16, ptr %15, align 2
  %205 = icmp uge i16 %204, 128
  br label %Block14

Then11:                                           ; preds = %Block14
  br label %Block10

Else11:                                           ; preds = %Block14
  br label %Block13

Block15:                                          ; preds = %IntMaxOk2, %Block16
  store i16 %197, ptr %15, align 2
  store i16 %197, ptr %16, align 2
  br label %Block11

Then12:                                           ; preds = %Block13
  store i64 0, ptr %8, align 8
  %206 = load i16, ptr %15, align 2
  %207 = zext i16 %206 to i64
  %208 = zext i16 %197 to i64
  %209 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %208, i64 %207)
  %210 = extractvalue { i64, i1 } %209, 1
  br i1 %210, label %OverflowFail3, label %OverflowOk3

Else12:                                           ; preds = %Block13
  %211 = load ptr, ptr %22, align 8
  %212 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %211, i32 0, i32 1
  %213 = load i16, ptr %15, align 2
  %214 = zext i16 %213 to i64
  %215 = icmp ult i64 %214, 128
  br i1 %215, label %Then15, label %Else15

OverflowFail3:                                    ; preds = %Then12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk3:                                      ; preds = %Then12
  %216 = extractvalue { i64, i1 } %209, 0
  br label %Loop3

Block16:                                          ; preds = %Else13
  br label %Block15

Loop3:                                            ; preds = %Block17, %OverflowOk3
  %217 = load i64, ptr %8, align 8
  %218 = icmp ult i64 %217, %216
  br i1 %218, label %Then13, label %Else13

Block17:                                          ; preds = %Block18
  %219 = add nuw i64 %217, 1
  store i64 %219, ptr %8, align 8
  br label %Loop3

Then13:                                           ; preds = %Loop3
  %220 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %207, i64 %217)
  %221 = extractvalue { i64, i1 } %220, 1
  br i1 %221, label %OverflowFail4, label %OverflowOk4

Else13:                                           ; preds = %Loop3
  br label %Block16

OverflowFail4:                                    ; preds = %Then13
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk4:                                      ; preds = %Then13
  %222 = extractvalue { i64, i1 } %220, 0
  store i64 %222, ptr %7, align 8
  %223 = load ptr, ptr %22, align 8
  %224 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %223, i32 0, i32 1
  %225 = icmp ult i64 %222, 128
  br i1 %225, label %Then14, label %Else14

Block18:                                          ; preds = %Then14
  %226 = getelementptr inbounds [128 x i46], ptr %224, i64 0, i64 %222
  %227 = load i64, ptr %171, align 8
  %228 = trunc i64 %227 to i46
  store i46 %228, ptr %226, align 8
  br label %Block17

Then14:                                           ; preds = %OverflowOk4
  br label %Block18

Else14:                                           ; preds = %OverflowOk4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %222, i64 128)
  unreachable

Block19:                                          ; preds = %Then15
  %229 = getelementptr inbounds [128 x i46], ptr %212, i64 0, i64 %214
  store ptr %229, ptr %6, align 8
  store ptr %229, ptr %5, align 8
  %230 = load i48, ptr %229, align 8
  %231 = lshr i48 %230, 30
  %232 = trunc i48 %231 to i16
  store i16 %232, ptr %4, align 2
  %233 = load ptr, ptr %6, align 8
  %234 = icmp ule i64 %168, 65535
  br i1 %234, label %IntMaxOk2, label %IntMaxFail2

Then15:                                           ; preds = %Else12
  br label %Block19

Else15:                                           ; preds = %Else12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %214, i64 128)
  unreachable

IntMaxFail2:                                      ; preds = %Block19
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk2:                                        ; preds = %Block19
  %235 = trunc i64 %168 to i16
  %236 = load i48, ptr %233, align 8
  %237 = zext i16 -1 to i48
  %238 = shl i48 %237, 30
  %239 = xor i48 %238, -1
  %240 = and i48 %236, %239
  %241 = zext i16 %235 to i48
  %242 = shl i48 %241, 30
  %243 = or i48 %242, %240
  store i48 %243, ptr %233, align 8
  %244 = load ptr, ptr %13, align 8
  %245 = load i48, ptr %244, align 8
  %246 = zext i16 -1 to i48
  %247 = shl i48 %246, 30
  %248 = xor i48 %247, -1
  %249 = and i48 %245, %248
  %250 = zext i16 %232 to i48
  %251 = shl i48 %250, 30
  %252 = or i48 %251, %249
  store i48 %252, ptr %244, align 8
  br label %Block15
}

; Function Attrs: nounwind uwtable
declare fastcc void @sort.heap__anon_18649(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i4, i1 } @llvm.usub.with.overflow.i4(i4, i4) #1

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.peekBitsEnding__anon_18682(ptr noalias nonnull sret({ i16, i7, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i6 @llvm.usub.sat.i6(i6, i6) #1

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.peekBits__anon_18665(ptr noalias nonnull sret({ i16, i7, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.peekArray__anon_18673(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
define internal fastcc void @"compress.flate.Decompress.HuffmanDecoder(19,7,7).find"(ptr noalias nonnull sret({ i46, i16, [6 x i8] }) %0, ptr nonnull %1, ptr nonnull align 8 %2, i16 %3) unnamed_addr #0 {
Entry:
  %4 = alloca { i46, i16, [6 x i8] }, align 8
  %5 = alloca i4, align 1
  %6 = alloca i46, align 8
  %7 = alloca i16, align 2
  %8 = alloca i16, align 2
  %9 = alloca i16, align 2
  %10 = alloca ptr, align 8
  %11 = alloca { i46, i16, [6 x i8] }, align 8
  %12 = alloca i46, align 8
  %13 = alloca i16, align 2
  %14 = alloca ptr, align 8
  %15 = alloca i16, align 2
  %16 = alloca ptr, align 8
  store ptr %2, ptr %16, align 8
  store i16 %3, ptr %15, align 2
  store ptr %2, ptr %14, align 8
  store i16 %3, ptr %13, align 2
  %17 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %2, i32 0, i32 1
  %18 = zext i16 %3 to i64
  %19 = icmp ult i64 %18, 128
  br i1 %19, label %Then, label %Else

Block:                                            ; preds = %Then
  %20 = getelementptr inbounds [128 x i46], ptr %17, i64 0, i64 %18
  %21 = load i64, ptr %20, align 8
  %22 = trunc i64 %21 to i46
  store i46 %22, ptr %12, align 8
  %23 = lshr i46 %22, 8
  %24 = trunc i46 %23 to i4
  %25 = icmp ne i4 %24, 0
  br i1 %25, label %Then1, label %Else1

Then:                                             ; preds = %Entry
  br label %Block

Else:                                             ; preds = %Entry
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 %18, i64 128)
  unreachable

Block1:                                           ; preds = %Else1
  %26 = load ptr, ptr %14, align 8
  %27 = lshr i46 %22, 30
  %28 = trunc i46 %27 to i16
  store ptr %26, ptr %10, align 8
  store i16 %3, ptr %9, align 2
  store i16 %28, ptr %8, align 2
  store i16 %28, ptr %7, align 2
  br label %Loop

Then1:                                            ; preds = %Block
  %29 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %11, i32 0, i32 1
  store i16 0, ptr %29, align 2
  %30 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %11, i32 0, i32 0
  store i46 %22, ptr %30, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %11, i64 16, i1 false)
  ret void

Else1:                                            ; preds = %Block
  br label %Block1

Block2:                                           ; preds = %Then4, %Block3
  %31 = phi ptr [ %4, %Then4 ], [ @609, %Block3 ]
  %32 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %31, i32 0, i32 1
  %33 = load i16, ptr %32, align 2
  %34 = icmp eq i16 %33, 0
  br i1 %34, label %Then5, label %Else5

Block3:                                           ; preds = %Else2
  br label %Block2

Loop:                                             ; preds = %Block4, %Block1
  %35 = load i16, ptr %7, align 2
  %36 = icmp ugt i16 %35, 0
  br i1 %36, label %Then2, label %Else2

Block4:                                           ; preds = %Block5
  br label %Loop

Then2:                                            ; preds = %Loop
  %37 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(19,7,7)", ptr %26, i32 0, i32 0
  %38 = load i16, ptr %7, align 2
  %39 = zext i16 %38 to i64
  %40 = icmp ult i64 %39, 19
  br i1 %40, label %Then3, label %Else3

Else2:                                            ; preds = %Loop
  br label %Block3

Block5:                                           ; preds = %Block7
  br label %Block4

Block6:                                           ; preds = %Then3
  %41 = getelementptr inbounds [19 x i46], ptr %37, i64 0, i64 %39
  %42 = load i64, ptr %41, align 8
  %43 = trunc i64 %42 to i46
  store i46 %43, ptr %6, align 8
  %44 = lshr i46 %43, 8
  %45 = trunc i46 %44 to i4
  %46 = call { i4, i1 } @llvm.usub.with.overflow.i4(i4 7, i4 %45)
  %47 = extractvalue { i4, i1 } %46, 1
  br i1 %47, label %OverflowFail, label %OverflowOk

Then3:                                            ; preds = %Then2
  br label %Block6

Else3:                                            ; preds = %Then2
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %1, i64 %39, i64 19)
  unreachable

OverflowFail:                                     ; preds = %Block6
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %1)
  unreachable

OverflowOk:                                       ; preds = %Block6
  %48 = extractvalue { i4, i1 } %46, 0
  store i4 %48, ptr %5, align 1
  %49 = lshr i46 %43, 14
  %50 = trunc i46 %49 to i16
  %51 = xor i16 %3, %50
  %52 = zext i4 %48 to i16
  %53 = lshr i16 %51, %52
  %54 = icmp eq i16 %53, 0
  br i1 %54, label %Then4, label %Else4

Block7:                                           ; preds = %Else4
  %55 = lshr i46 %43, 30
  %56 = trunc i46 %55 to i16
  store i16 %56, ptr %7, align 2
  br label %Block5

Then4:                                            ; preds = %OverflowOk
  %57 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %4, i32 0, i32 1
  store i16 0, ptr %57, align 2
  %58 = getelementptr inbounds { i46, i16, [6 x i8] }, ptr %4, i32 0, i32 0
  store i46 %43, ptr %58, align 8
  br label %Block2

Else4:                                            ; preds = %OverflowOk
  br label %Block7

Then5:                                            ; preds = %Block2
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %31, i64 16, i1 false)
  ret void

Else5:                                            ; preds = %Block2
  notail call fastcc void @builtin.returnError(ptr %1) #15
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %31, i64 16, i1 false)
  ret void
}

; Function Attrs: nounwind uwtable
declare fastcc i16 @compress.flate.Decompress.tossBitsEnding(ptr nonnull, ptr nonnull align 8, i4)

; Function Attrs: nounwind uwtable
declare fastcc i16 @compress.flate.Decompress.tossBits(ptr nonnull, ptr nonnull align 8, i4)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBitsEnding__anon_18740(ptr noalias nonnull sret({ i16, i7, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBits__anon_18734(ptr noalias nonnull sret({ i16, i7, [1 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.dynamicCodeLength(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i16, ptr nonnull align 1, i64, i64)

; Function Attrs: nounwind uwtable
define internal fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(286,15,9).checkCompleteness"(ptr nonnull %0, ptr nonnull readonly align 1 %1, i64 %2) unnamed_addr #0 {
Entry:
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = alloca i4, align 1
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca [16 x i16], align 2
  %10 = alloca { ptr, i64 }, align 8
  %11 = insertvalue { ptr, i64 } poison, ptr %1, 0
  %12 = insertvalue { ptr, i64 } %11, i64 %2, 1
  store { ptr, i64 } %12, ptr %10, align 8
  %13 = extractvalue { ptr, i64 } %12, 1
  %14 = icmp ult i64 256, %13
  br i1 %14, label %Then, label %Else

Block:                                            ; preds = %Else1
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %9, ptr align 2 @615, i64 32, i1 false)
  store i64 0, ptr %8, align 8
  store i64 0, ptr %7, align 8
  %15 = extractvalue { ptr, i64 } %12, 1
  br label %Loop

Block1:                                           ; preds = %Then
  %16 = extractvalue { ptr, i64 } %12, 0
  %17 = getelementptr inbounds i4, ptr %16, i64 256
  %18 = load i8, ptr %17, align 1
  %19 = trunc i8 %18 to i4
  %20 = icmp eq i4 %19, 0
  br i1 %20, label %Then1, label %Else1

Then:                                             ; preds = %Entry
  br label %Block1

Else:                                             ; preds = %Entry
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 256, i64 %13)
  unreachable

Then1:                                            ; preds = %Block1
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 94

Else1:                                            ; preds = %Block1
  br label %Block

Block2:                                           ; preds = %Else2
  %21 = load i64, ptr %8, align 8
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %Then6, label %Else6

Loop:                                             ; preds = %Block3, %Block
  %23 = load i64, ptr %7, align 8
  %24 = icmp ult i64 %23, %15
  br i1 %24, label %Then2, label %Else2

Block3:                                           ; preds = %OverflowOk, %Then3
  %25 = add nuw i64 %23, 1
  store i64 %25, ptr %7, align 8
  br label %Loop

Then2:                                            ; preds = %Loop
  %26 = extractvalue { ptr, i64 } %12, 0
  %27 = getelementptr inbounds i4, ptr %26, i64 %23
  %28 = load i8, ptr %27, align 1
  %29 = trunc i8 %28 to i4
  store i4 %29, ptr %6, align 1
  %30 = icmp eq i4 %29, 0
  br i1 %30, label %Then3, label %Else3

Else2:                                            ; preds = %Loop
  br label %Block2

Block4:                                           ; preds = %Else3
  %31 = load i64, ptr %8, align 8
  %32 = zext i4 %29 to i64
  %33 = icmp ugt i64 %32, %31
  br i1 %33, label %Then4, label %Else4

Then3:                                            ; preds = %Then2
  br label %Block3

Else3:                                            ; preds = %Then2
  br label %Block4

Block5:                                           ; preds = %Else4, %Then4
  %34 = zext i4 %29 to i64
  %35 = icmp ult i64 %34, 16
  br i1 %35, label %Then5, label %Else5

Then4:                                            ; preds = %Block4
  %36 = zext i4 %29 to i64
  store i64 %36, ptr %8, align 8
  br label %Block5

Else4:                                            ; preds = %Block4
  br label %Block5

Block6:                                           ; preds = %Then5
  %37 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 %34
  %38 = load i16, ptr %37, align 2
  %39 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %38, i16 1)
  %40 = extractvalue { i16, i1 } %39, 1
  br i1 %40, label %OverflowFail, label %OverflowOk

Then5:                                            ; preds = %Block5
  br label %Block6

Else5:                                            ; preds = %Block5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %34, i64 16)
  unreachable

OverflowFail:                                     ; preds = %Block6
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk:                                       ; preds = %Block6
  %41 = extractvalue { i16, i1 } %39, 0
  store i16 %41, ptr %37, align 2
  br label %Block3

Block7:                                           ; preds = %Else6
  store i64 1, ptr %5, align 8
  store i64 0, ptr %4, align 8
  br label %Loop1

Then6:                                            ; preds = %Block2
  ret i16 0

Else6:                                            ; preds = %Block2
  br label %Block7

Block8:                                           ; preds = %Else7
  %42 = load i64, ptr %5, align 8
  %43 = icmp ugt i64 %42, 0
  br i1 %43, label %Then11, label %Else11

Loop1:                                            ; preds = %Block9, %Block7
  %44 = load i64, ptr %4, align 8
  %45 = icmp ult i64 %44, 15
  br i1 %45, label %Then7, label %Else7

Block9:                                           ; preds = %OverflowOk2
  %46 = add nuw i64 %44, 1
  store i64 %46, ptr %4, align 8
  br label %Loop1

Then7:                                            ; preds = %Loop1
  %47 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 1, i64 %44)
  %48 = extractvalue { i64, i1 } %47, 1
  br i1 %48, label %OverflowFail1, label %OverflowOk1

Else7:                                            ; preds = %Loop1
  br label %Block8

OverflowFail1:                                    ; preds = %Then7
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk1:                                      ; preds = %Then7
  %49 = extractvalue { i64, i1 } %47, 0
  store i64 %49, ptr %3, align 8
  %50 = load i64, ptr %5, align 8
  %51 = zext i6 1 to i64
  %52 = shl i64 %50, %51
  store i64 %52, ptr %5, align 8
  %53 = icmp ult i64 %49, 16
  br i1 %53, label %Then8, label %Else8

Block10:                                          ; preds = %Else9
  %54 = load i64, ptr %5, align 8
  %55 = icmp ult i64 %49, 16
  br i1 %55, label %Then10, label %Else10

Block11:                                          ; preds = %Then8
  %56 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 %49
  %57 = load i16, ptr %56, align 2
  %58 = load i64, ptr %5, align 8
  %59 = zext i16 %57 to i64
  %60 = icmp ugt i64 %59, %58
  br i1 %60, label %Then9, label %Else9

Then8:                                            ; preds = %OverflowOk1
  br label %Block11

Else8:                                            ; preds = %OverflowOk1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %49, i64 16)
  unreachable

Then9:                                            ; preds = %Block11
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 92

Else9:                                            ; preds = %Block11
  br label %Block10

Block12:                                          ; preds = %Then10
  %61 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 %49
  %62 = load i16, ptr %61, align 2
  %63 = zext i16 %62 to i64
  %64 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %54, i64 %63)
  %65 = extractvalue { i64, i1 } %64, 1
  br i1 %65, label %OverflowFail2, label %OverflowOk2

Then10:                                           ; preds = %Block10
  br label %Block12

Else10:                                           ; preds = %Block10
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %49, i64 16)
  unreachable

OverflowFail2:                                    ; preds = %Block12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk2:                                      ; preds = %Block12
  %66 = extractvalue { i64, i1 } %64, 0
  store i64 %66, ptr %5, align 8
  br label %Block9

Block13:                                          ; preds = %Else11
  ret i16 0

Then11:                                           ; preds = %Block8
  %67 = load i64, ptr %8, align 8
  %68 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 0
  %69 = load i16, ptr %68, align 2
  %70 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 1
  %71 = load i16, ptr %70, align 2
  %72 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %69, i16 %71)
  %73 = extractvalue { i16, i1 } %72, 1
  br i1 %73, label %OverflowFail3, label %OverflowOk3

Else11:                                           ; preds = %Block8
  br label %Block13

Block14:                                          ; preds = %Else12
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 93

OverflowFail3:                                    ; preds = %Then11
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk3:                                      ; preds = %Then11
  %74 = extractvalue { i16, i1 } %72, 0
  %75 = zext i16 %74 to i64
  %76 = icmp eq i64 %67, %75
  br i1 %76, label %Then12, label %Else12

Then12:                                           ; preds = %OverflowOk3
  ret i16 0

Else12:                                           ; preds = %OverflowOk3
  br label %Block14
}

; Function Attrs: nounwind uwtable
define internal fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(286,15,9).generate"(ptr nonnull %0, ptr nonnull align 8 %1, ptr nonnull readonly align 1 %2, i64 %3) unnamed_addr #0 {
Entry:
  %4 = alloca i16, align 2
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i16, align 2
  %10 = alloca i16, align 2
  %11 = alloca i64, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca i64, align 8
  %15 = alloca i16, align 2
  %16 = alloca i16, align 2
  %17 = alloca i64, align 8
  %18 = alloca i64, align 8
  %19 = alloca i4, align 1
  %20 = alloca i64, align 8
  %21 = alloca i64, align 8
  %22 = alloca ptr, align 8
  %23 = alloca { ptr, i64 }, align 8
  %24 = alloca ptr, align 8
  %25 = insertvalue { ptr, i64 } poison, ptr %2, 0
  %26 = insertvalue { ptr, i64 } %25, i64 %3, 1
  store ptr %1, ptr %24, align 8
  store { ptr, i64 } %26, ptr %23, align 8
  store ptr %1, ptr %22, align 8
  %27 = extractvalue { ptr, i64 } %26, 0
  %28 = extractvalue { ptr, i64 } %26, 1
  %29 = call fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(286,15,9).checkCompleteness"(ptr %0, ptr nonnull readonly align 1 %27, i64 %28)
  %30 = icmp ne i16 %29, 0
  br i1 %30, label %TryRet, label %TryCont

TryRet:                                           ; preds = %Entry
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 %29

TryCont:                                          ; preds = %Entry
  store i64 0, ptr %21, align 8
  br label %Loop

Block:                                            ; preds = %Else
  %31 = load ptr, ptr %22, align 8
  %32 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(286,15,9)", ptr %31, i32 0, i32 0
  %33 = getelementptr inbounds [286 x i46], ptr %32, i64 0, i64 0
  %34 = insertvalue { ptr, i64 } poison, ptr %33, 0
  %35 = insertvalue { ptr, i64 } %34, i64 286, 1
  %36 = extractvalue { ptr, i64 } %35, 0
  %37 = extractvalue { ptr, i64 } %35, 1
  call fastcc void @sort.heap__anon_18649(ptr %0, ptr nonnull align 8 %36, i64 %37)
  store i64 0, ptr %18, align 8
  br label %Loop1

Loop:                                             ; preds = %Block1, %TryCont
  %38 = load i64, ptr %21, align 8
  %39 = icmp ult i64 %38, 286
  br i1 %39, label %Then, label %Else

Block1:                                           ; preds = %Block5
  %40 = add nuw i64 %38, 1
  store i64 %40, ptr %21, align 8
  br label %Loop

Then:                                             ; preds = %Loop
  store i64 %38, ptr %20, align 8
  %41 = extractvalue { ptr, i64 } %26, 1
  %42 = icmp ult i64 %38, %41
  br i1 %42, label %Then1, label %Else1

Else:                                             ; preds = %Loop
  br label %Block

Block2:                                           ; preds = %Block3, %Else1
  %43 = phi i4 [ %52, %Block3 ], [ 0, %Else1 ]
  store i4 %43, ptr %19, align 1
  %44 = load ptr, ptr %22, align 8
  %45 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(286,15,9)", ptr %44, i32 0, i32 0
  %46 = icmp ult i64 %38, 286
  br i1 %46, label %Then3, label %Else3

Then1:                                            ; preds = %Then
  %47 = extractvalue { ptr, i64 } %26, 1
  %48 = icmp ult i64 %38, %47
  br i1 %48, label %Then2, label %Else2

Else1:                                            ; preds = %Then
  br label %Block2

Block3:                                           ; preds = %Then2
  %49 = extractvalue { ptr, i64 } %26, 0
  %50 = getelementptr inbounds i4, ptr %49, i64 %38
  %51 = load i8, ptr %50, align 1
  %52 = trunc i8 %51 to i4
  br label %Block2

Then2:                                            ; preds = %Then1
  br label %Block3

Else2:                                            ; preds = %Then1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %38, i64 %47)
  unreachable

Block4:                                           ; preds = %Then3
  %53 = getelementptr inbounds [286 x i46], ptr %45, i64 0, i64 %38
  %54 = icmp ult i64 %38, 256
  br i1 %54, label %Then4, label %Else4

Then3:                                            ; preds = %Block2
  br label %Block4

Else3:                                            ; preds = %Block2
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %38, i64 286)
  unreachable

Block5:                                           ; preds = %Block6, %IntMaxOk
  br label %Block1

Then4:                                            ; preds = %Block4
  %55 = load i48, ptr %53, align 8
  %56 = zext i2 -1 to i48
  %57 = shl i48 %56, 12
  %58 = xor i48 %57, -1
  %59 = and i48 %55, %58
  %60 = zext i2 0 to i48
  %61 = shl i48 %60, 12
  %62 = or i48 %61, %59
  store i48 %62, ptr %53, align 8
  %63 = icmp ule i64 %38, 255
  br i1 %63, label %IntMaxOk, label %IntMaxFail

Else4:                                            ; preds = %Block4
  %64 = icmp eq i64 %38, 256
  br i1 %64, label %Then5, label %Else5

IntMaxFail:                                       ; preds = %Then4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk:                                         ; preds = %Then4
  %65 = trunc i64 %38 to i8
  store i8 %65, ptr %53, align 8
  %66 = load i48, ptr %53, align 8
  %67 = zext i4 -1 to i48
  %68 = shl i48 %67, 8
  %69 = xor i48 %68, -1
  %70 = and i48 %66, %69
  %71 = zext i4 %43 to i48
  %72 = shl i48 %71, 8
  %73 = or i48 %72, %70
  store i48 %73, ptr %53, align 8
  %74 = load i48, ptr %53, align 8
  %75 = zext i16 -1 to i48
  %76 = shl i48 %75, 14
  %77 = xor i48 %76, -1
  %78 = and i48 %74, %77
  %79 = zext i16 0 to i48
  %80 = shl i48 %79, 14
  %81 = or i48 %80, %78
  store i48 %81, ptr %53, align 8
  %82 = load i48, ptr %53, align 8
  %83 = zext i16 -1 to i48
  %84 = shl i48 %83, 30
  %85 = xor i48 %84, -1
  %86 = and i48 %82, %85
  %87 = zext i16 0 to i48
  %88 = shl i48 %87, 30
  %89 = or i48 %88, %86
  store i48 %89, ptr %53, align 8
  br label %Block5

Block6:                                           ; preds = %IntMaxOk1, %Then5
  br label %Block5

Then5:                                            ; preds = %Else4
  %90 = load i48, ptr %53, align 8
  %91 = zext i2 -1 to i48
  %92 = shl i48 %91, 12
  %93 = xor i48 %92, -1
  %94 = and i48 %90, %93
  %95 = zext i2 1 to i48
  %96 = shl i48 %95, 12
  %97 = or i48 %96, %94
  store i48 %97, ptr %53, align 8
  store i8 -1, ptr %53, align 8
  %98 = load i48, ptr %53, align 8
  %99 = zext i4 -1 to i48
  %100 = shl i48 %99, 8
  %101 = xor i48 %100, -1
  %102 = and i48 %98, %101
  %103 = zext i4 %43 to i48
  %104 = shl i48 %103, 8
  %105 = or i48 %104, %102
  store i48 %105, ptr %53, align 8
  %106 = load i48, ptr %53, align 8
  %107 = zext i16 -1 to i48
  %108 = shl i48 %107, 14
  %109 = xor i48 %108, -1
  %110 = and i48 %106, %109
  %111 = zext i16 0 to i48
  %112 = shl i48 %111, 14
  %113 = or i48 %112, %110
  store i48 %113, ptr %53, align 8
  %114 = load i48, ptr %53, align 8
  %115 = zext i16 -1 to i48
  %116 = shl i48 %115, 30
  %117 = xor i48 %116, -1
  %118 = and i48 %114, %117
  %119 = zext i16 0 to i48
  %120 = shl i48 %119, 30
  %121 = or i48 %120, %118
  store i48 %121, ptr %53, align 8
  br label %Block6

Else5:                                            ; preds = %Else4
  %122 = load i48, ptr %53, align 8
  %123 = zext i2 -1 to i48
  %124 = shl i48 %123, 12
  %125 = xor i48 %124, -1
  %126 = and i48 %122, %125
  %127 = zext i2 -2 to i48
  %128 = shl i48 %127, 12
  %129 = or i48 %128, %126
  store i48 %129, ptr %53, align 8
  %130 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %38, i64 257)
  %131 = extractvalue { i64, i1 } %130, 1
  br i1 %131, label %OverflowFail, label %OverflowOk

OverflowFail:                                     ; preds = %Else5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk:                                       ; preds = %Else5
  %132 = extractvalue { i64, i1 } %130, 0
  %133 = icmp ule i64 %132, 255
  br i1 %133, label %IntMaxOk1, label %IntMaxFail1

IntMaxFail1:                                      ; preds = %OverflowOk
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk1:                                        ; preds = %OverflowOk
  %134 = trunc i64 %132 to i8
  store i8 %134, ptr %53, align 8
  %135 = load i48, ptr %53, align 8
  %136 = zext i4 -1 to i48
  %137 = shl i48 %136, 8
  %138 = xor i48 %137, -1
  %139 = and i48 %135, %138
  %140 = zext i4 %43 to i48
  %141 = shl i48 %140, 8
  %142 = or i48 %141, %139
  store i48 %142, ptr %53, align 8
  %143 = load i48, ptr %53, align 8
  %144 = zext i16 -1 to i48
  %145 = shl i48 %144, 14
  %146 = xor i48 %145, -1
  %147 = and i48 %143, %146
  %148 = zext i16 0 to i48
  %149 = shl i48 %148, 14
  %150 = or i48 %149, %147
  store i48 %150, ptr %53, align 8
  %151 = load i48, ptr %53, align 8
  %152 = zext i16 -1 to i48
  %153 = shl i48 %152, 30
  %154 = xor i48 %153, -1
  %155 = and i48 %151, %154
  %156 = zext i16 0 to i48
  %157 = shl i48 %156, 30
  %158 = or i48 %157, %155
  store i48 %158, ptr %53, align 8
  br label %Block6

Block7:                                           ; preds = %Else6
  store i16 0, ptr %16, align 2
  store i16 0, ptr %15, align 2
  store i64 0, ptr %14, align 8
  %159 = load ptr, ptr %22, align 8
  %160 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(286,15,9)", ptr %159, i32 0, i32 0
  br label %Loop2

Loop1:                                            ; preds = %Block8, %Block
  %161 = load i64, ptr %18, align 8
  %162 = icmp ult i64 %161, 512
  br i1 %162, label %Then6, label %Else6

Block8:                                           ; preds = %Block9
  %163 = add nuw i64 %161, 1
  store i64 %163, ptr %18, align 8
  br label %Loop1

Then6:                                            ; preds = %Loop1
  store i64 %161, ptr %17, align 8
  %164 = load ptr, ptr %22, align 8
  %165 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(286,15,9)", ptr %164, i32 0, i32 1
  %166 = icmp ult i64 %161, 512
  br i1 %166, label %Then7, label %Else7

Else6:                                            ; preds = %Loop1
  br label %Block7

Block9:                                           ; preds = %Then7
  %167 = getelementptr inbounds [512 x i46], ptr %165, i64 0, i64 %161
  store i46 0, ptr %167, align 8
  br label %Block8

Then7:                                            ; preds = %Then6
  br label %Block9

Else7:                                            ; preds = %Then6
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %161, i64 512)
  unreachable

Block10:                                          ; preds = %Then11, %Else8
  ret i16 0

Loop2:                                            ; preds = %Block11, %Block7
  %168 = load i64, ptr %14, align 8
  %169 = icmp ult i64 %168, 286
  br i1 %169, label %Then8, label %Else8

Block11:                                          ; preds = %Block15, %Then9
  %170 = add nuw i64 %168, 1
  store i64 %170, ptr %14, align 8
  br label %Loop2

Then8:                                            ; preds = %Loop2
  %171 = getelementptr inbounds [286 x i46], ptr %160, i64 0, i64 %168
  store ptr %171, ptr %13, align 8
  store ptr %171, ptr %12, align 8
  store i64 %168, ptr %11, align 8
  %172 = load i48, ptr %171, align 8
  %173 = lshr i48 %172, 8
  %174 = trunc i48 %173 to i4
  %175 = icmp eq i4 %174, 0
  br i1 %175, label %Then9, label %Else9

Else8:                                            ; preds = %Loop2
  br label %Block10

Block12:                                          ; preds = %Else9
  %176 = load ptr, ptr %13, align 8
  %177 = load i16, ptr %16, align 2
  %178 = load i48, ptr %176, align 8
  %179 = zext i16 -1 to i48
  %180 = shl i48 %179, 14
  %181 = xor i48 %180, -1
  %182 = and i48 %178, %181
  %183 = zext i16 %177 to i48
  %184 = shl i48 %183, 14
  %185 = or i48 %184, %182
  store i48 %185, ptr %176, align 8
  %186 = load i16, ptr %16, align 2
  %187 = load i48, ptr %171, align 8
  %188 = lshr i48 %187, 8
  %189 = trunc i48 %188 to i4
  %190 = call { i4, i1 } @llvm.usub.with.overflow.i4(i4 -1, i4 %189)
  %191 = extractvalue { i4, i1 } %190, 1
  br i1 %191, label %OverflowFail1, label %OverflowOk1

Then9:                                            ; preds = %Then8
  br label %Block11

Else9:                                            ; preds = %Then8
  br label %Block12

OverflowFail1:                                    ; preds = %Block12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk1:                                      ; preds = %Block12
  %192 = extractvalue { i4, i1 } %190, 0
  %193 = zext i4 %192 to i16
  %194 = shl i16 1, %193
  %195 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %186, i16 %194)
  %196 = extractvalue { i16, i1 } %195, 1
  br i1 %196, label %OverflowFail2, label %OverflowOk2

OverflowFail2:                                    ; preds = %OverflowOk1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk2:                                      ; preds = %OverflowOk1
  %197 = extractvalue { i16, i1 } %195, 0
  store i16 %197, ptr %10, align 2
  %198 = zext i4 6 to i16
  %199 = lshr i16 %197, %198
  store i16 %199, ptr %9, align 2
  %200 = icmp ugt i16 %199, 512
  br i1 %200, label %Then10, label %Else10

Block13:                                          ; preds = %Else11
  %201 = load i48, ptr %171, align 8
  %202 = lshr i48 %201, 8
  %203 = trunc i48 %202 to i4
  %204 = icmp ule i4 %203, -7
  br i1 %204, label %Then12, label %Else12

Block14:                                          ; preds = %Else10, %Then10
  %205 = phi i1 [ true, %Then10 ], [ %207, %Else10 ]
  br i1 %205, label %Then11, label %Else11

Then10:                                           ; preds = %OverflowOk2
  br label %Block14

Else10:                                           ; preds = %OverflowOk2
  %206 = load i16, ptr %15, align 2
  %207 = icmp uge i16 %206, 512
  br label %Block14

Then11:                                           ; preds = %Block14
  br label %Block10

Else11:                                           ; preds = %Block14
  br label %Block13

Block15:                                          ; preds = %IntMaxOk2, %Block16
  store i16 %199, ptr %15, align 2
  store i16 %197, ptr %16, align 2
  br label %Block11

Then12:                                           ; preds = %Block13
  store i64 0, ptr %8, align 8
  %208 = load i16, ptr %15, align 2
  %209 = zext i16 %208 to i64
  %210 = zext i16 %199 to i64
  %211 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %210, i64 %209)
  %212 = extractvalue { i64, i1 } %211, 1
  br i1 %212, label %OverflowFail3, label %OverflowOk3

Else12:                                           ; preds = %Block13
  %213 = load ptr, ptr %22, align 8
  %214 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(286,15,9)", ptr %213, i32 0, i32 1
  %215 = load i16, ptr %15, align 2
  %216 = zext i16 %215 to i64
  %217 = icmp ult i64 %216, 512
  br i1 %217, label %Then15, label %Else15

OverflowFail3:                                    ; preds = %Then12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk3:                                      ; preds = %Then12
  %218 = extractvalue { i64, i1 } %211, 0
  br label %Loop3

Block16:                                          ; preds = %Else13
  br label %Block15

Loop3:                                            ; preds = %Block17, %OverflowOk3
  %219 = load i64, ptr %8, align 8
  %220 = icmp ult i64 %219, %218
  br i1 %220, label %Then13, label %Else13

Block17:                                          ; preds = %Block18
  %221 = add nuw i64 %219, 1
  store i64 %221, ptr %8, align 8
  br label %Loop3

Then13:                                           ; preds = %Loop3
  %222 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %209, i64 %219)
  %223 = extractvalue { i64, i1 } %222, 1
  br i1 %223, label %OverflowFail4, label %OverflowOk4

Else13:                                           ; preds = %Loop3
  br label %Block16

OverflowFail4:                                    ; preds = %Then13
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk4:                                      ; preds = %Then13
  %224 = extractvalue { i64, i1 } %222, 0
  store i64 %224, ptr %7, align 8
  %225 = load ptr, ptr %22, align 8
  %226 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(286,15,9)", ptr %225, i32 0, i32 1
  %227 = icmp ult i64 %224, 512
  br i1 %227, label %Then14, label %Else14

Block18:                                          ; preds = %Then14
  %228 = getelementptr inbounds [512 x i46], ptr %226, i64 0, i64 %224
  %229 = load i64, ptr %171, align 8
  %230 = trunc i64 %229 to i46
  store i46 %230, ptr %228, align 8
  br label %Block17

Then14:                                           ; preds = %OverflowOk4
  br label %Block18

Else14:                                           ; preds = %OverflowOk4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %224, i64 512)
  unreachable

Block19:                                          ; preds = %Then15
  %231 = getelementptr inbounds [512 x i46], ptr %214, i64 0, i64 %216
  store ptr %231, ptr %6, align 8
  store ptr %231, ptr %5, align 8
  %232 = load i48, ptr %231, align 8
  %233 = lshr i48 %232, 30
  %234 = trunc i48 %233 to i16
  store i16 %234, ptr %4, align 2
  %235 = load ptr, ptr %6, align 8
  %236 = icmp ule i64 %168, 65535
  br i1 %236, label %IntMaxOk2, label %IntMaxFail2

Then15:                                           ; preds = %Else12
  br label %Block19

Else15:                                           ; preds = %Else12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %216, i64 512)
  unreachable

IntMaxFail2:                                      ; preds = %Block19
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk2:                                        ; preds = %Block19
  %237 = trunc i64 %168 to i16
  %238 = load i48, ptr %235, align 8
  %239 = zext i16 -1 to i48
  %240 = shl i48 %239, 30
  %241 = xor i48 %240, -1
  %242 = and i48 %238, %241
  %243 = zext i16 %237 to i48
  %244 = shl i48 %243, 30
  %245 = or i48 %244, %242
  store i48 %245, ptr %235, align 8
  %246 = load ptr, ptr %13, align 8
  %247 = load i48, ptr %246, align 8
  %248 = zext i16 -1 to i48
  %249 = shl i48 %248, 30
  %250 = xor i48 %249, -1
  %251 = and i48 %247, %250
  %252 = zext i16 %234 to i48
  %253 = shl i48 %252, 30
  %254 = or i48 %253, %251
  store i48 %254, ptr %246, align 8
  br label %Block15
}

; Function Attrs: nounwind uwtable
define internal fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(30,15,9).checkCompleteness"(ptr nonnull %0, ptr nonnull readonly align 1 %1, i64 %2) unnamed_addr #0 {
Entry:
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = alloca i4, align 1
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca [16 x i16], align 2
  %10 = alloca { ptr, i64 }, align 8
  %11 = insertvalue { ptr, i64 } poison, ptr %1, 0
  %12 = insertvalue { ptr, i64 } %11, i64 %2, 1
  store { ptr, i64 } %12, ptr %10, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 2 %9, ptr align 2 @616, i64 32, i1 false)
  store i64 0, ptr %8, align 8
  store i64 0, ptr %7, align 8
  %13 = extractvalue { ptr, i64 } %12, 1
  br label %Loop

Block:                                            ; preds = %Else
  %14 = load i64, ptr %8, align 8
  %15 = icmp eq i64 %14, 0
  br i1 %15, label %Then4, label %Else4

Loop:                                             ; preds = %Block1, %Entry
  %16 = load i64, ptr %7, align 8
  %17 = icmp ult i64 %16, %13
  br i1 %17, label %Then, label %Else

Block1:                                           ; preds = %OverflowOk, %Then1
  %18 = add nuw i64 %16, 1
  store i64 %18, ptr %7, align 8
  br label %Loop

Then:                                             ; preds = %Loop
  %19 = extractvalue { ptr, i64 } %12, 0
  %20 = getelementptr inbounds i4, ptr %19, i64 %16
  %21 = load i8, ptr %20, align 1
  %22 = trunc i8 %21 to i4
  store i4 %22, ptr %6, align 1
  %23 = icmp eq i4 %22, 0
  br i1 %23, label %Then1, label %Else1

Else:                                             ; preds = %Loop
  br label %Block

Block2:                                           ; preds = %Else1
  %24 = load i64, ptr %8, align 8
  %25 = zext i4 %22 to i64
  %26 = icmp ugt i64 %25, %24
  br i1 %26, label %Then2, label %Else2

Then1:                                            ; preds = %Then
  br label %Block1

Else1:                                            ; preds = %Then
  br label %Block2

Block3:                                           ; preds = %Else2, %Then2
  %27 = zext i4 %22 to i64
  %28 = icmp ult i64 %27, 16
  br i1 %28, label %Then3, label %Else3

Then2:                                            ; preds = %Block2
  %29 = zext i4 %22 to i64
  store i64 %29, ptr %8, align 8
  br label %Block3

Else2:                                            ; preds = %Block2
  br label %Block3

Block4:                                           ; preds = %Then3
  %30 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 %27
  %31 = load i16, ptr %30, align 2
  %32 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %31, i16 1)
  %33 = extractvalue { i16, i1 } %32, 1
  br i1 %33, label %OverflowFail, label %OverflowOk

Then3:                                            ; preds = %Block3
  br label %Block4

Else3:                                            ; preds = %Block3
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %27, i64 16)
  unreachable

OverflowFail:                                     ; preds = %Block4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk:                                       ; preds = %Block4
  %34 = extractvalue { i16, i1 } %32, 0
  store i16 %34, ptr %30, align 2
  br label %Block1

Block5:                                           ; preds = %Else4
  store i64 1, ptr %5, align 8
  store i64 0, ptr %4, align 8
  br label %Loop1

Then4:                                            ; preds = %Block
  ret i16 0

Else4:                                            ; preds = %Block
  br label %Block5

Block6:                                           ; preds = %Else5
  %35 = load i64, ptr %5, align 8
  %36 = icmp ugt i64 %35, 0
  br i1 %36, label %Then9, label %Else9

Loop1:                                            ; preds = %Block7, %Block5
  %37 = load i64, ptr %4, align 8
  %38 = icmp ult i64 %37, 15
  br i1 %38, label %Then5, label %Else5

Block7:                                           ; preds = %OverflowOk2
  %39 = add nuw i64 %37, 1
  store i64 %39, ptr %4, align 8
  br label %Loop1

Then5:                                            ; preds = %Loop1
  %40 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 1, i64 %37)
  %41 = extractvalue { i64, i1 } %40, 1
  br i1 %41, label %OverflowFail1, label %OverflowOk1

Else5:                                            ; preds = %Loop1
  br label %Block6

OverflowFail1:                                    ; preds = %Then5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk1:                                      ; preds = %Then5
  %42 = extractvalue { i64, i1 } %40, 0
  store i64 %42, ptr %3, align 8
  %43 = load i64, ptr %5, align 8
  %44 = zext i6 1 to i64
  %45 = shl i64 %43, %44
  store i64 %45, ptr %5, align 8
  %46 = icmp ult i64 %42, 16
  br i1 %46, label %Then6, label %Else6

Block8:                                           ; preds = %Else7
  %47 = load i64, ptr %5, align 8
  %48 = icmp ult i64 %42, 16
  br i1 %48, label %Then8, label %Else8

Block9:                                           ; preds = %Then6
  %49 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 %42
  %50 = load i16, ptr %49, align 2
  %51 = load i64, ptr %5, align 8
  %52 = zext i16 %50 to i64
  %53 = icmp ugt i64 %52, %51
  br i1 %53, label %Then7, label %Else7

Then6:                                            ; preds = %OverflowOk1
  br label %Block9

Else6:                                            ; preds = %OverflowOk1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %42, i64 16)
  unreachable

Then7:                                            ; preds = %Block9
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 92

Else7:                                            ; preds = %Block9
  br label %Block8

Block10:                                          ; preds = %Then8
  %54 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 %42
  %55 = load i16, ptr %54, align 2
  %56 = zext i16 %55 to i64
  %57 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %47, i64 %56)
  %58 = extractvalue { i64, i1 } %57, 1
  br i1 %58, label %OverflowFail2, label %OverflowOk2

Then8:                                            ; preds = %Block8
  br label %Block10

Else8:                                            ; preds = %Block8
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %42, i64 16)
  unreachable

OverflowFail2:                                    ; preds = %Block10
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk2:                                      ; preds = %Block10
  %59 = extractvalue { i64, i1 } %57, 0
  store i64 %59, ptr %5, align 8
  br label %Block7

Block11:                                          ; preds = %Else9
  ret i16 0

Then9:                                            ; preds = %Block6
  %60 = load i64, ptr %8, align 8
  %61 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 0
  %62 = load i16, ptr %61, align 2
  %63 = getelementptr inbounds [16 x i16], ptr %9, i64 0, i64 1
  %64 = load i16, ptr %63, align 2
  %65 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %62, i16 %64)
  %66 = extractvalue { i16, i1 } %65, 1
  br i1 %66, label %OverflowFail3, label %OverflowOk3

Else9:                                            ; preds = %Block6
  br label %Block11

Block12:                                          ; preds = %Else10
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 93

OverflowFail3:                                    ; preds = %Then9
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk3:                                      ; preds = %Then9
  %67 = extractvalue { i16, i1 } %65, 0
  %68 = zext i16 %67 to i64
  %69 = icmp eq i64 %60, %68
  br i1 %69, label %Then10, label %Else10

Then10:                                           ; preds = %OverflowOk3
  ret i16 0

Else10:                                           ; preds = %OverflowOk3
  br label %Block12
}

; Function Attrs: nounwind uwtable
define internal fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(30,15,9).generate"(ptr nonnull %0, ptr nonnull align 8 %1, ptr nonnull readonly align 1 %2, i64 %3) unnamed_addr #0 {
Entry:
  %4 = alloca i16, align 2
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i16, align 2
  %10 = alloca i16, align 2
  %11 = alloca i64, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca i64, align 8
  %15 = alloca i16, align 2
  %16 = alloca i16, align 2
  %17 = alloca i64, align 8
  %18 = alloca i64, align 8
  %19 = alloca i4, align 1
  %20 = alloca i64, align 8
  %21 = alloca i64, align 8
  %22 = alloca ptr, align 8
  %23 = alloca { ptr, i64 }, align 8
  %24 = alloca ptr, align 8
  %25 = insertvalue { ptr, i64 } poison, ptr %2, 0
  %26 = insertvalue { ptr, i64 } %25, i64 %3, 1
  store ptr %1, ptr %24, align 8
  store { ptr, i64 } %26, ptr %23, align 8
  store ptr %1, ptr %22, align 8
  %27 = extractvalue { ptr, i64 } %26, 0
  %28 = extractvalue { ptr, i64 } %26, 1
  %29 = call fastcc i16 @"compress.flate.Decompress.HuffmanDecoder(30,15,9).checkCompleteness"(ptr %0, ptr nonnull readonly align 1 %27, i64 %28)
  %30 = icmp ne i16 %29, 0
  br i1 %30, label %TryRet, label %TryCont

TryRet:                                           ; preds = %Entry
  notail call fastcc void @builtin.returnError(ptr %0) #15
  ret i16 %29

TryCont:                                          ; preds = %Entry
  store i64 0, ptr %21, align 8
  br label %Loop

Block:                                            ; preds = %Else
  %31 = load ptr, ptr %22, align 8
  %32 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(30,15,9)", ptr %31, i32 0, i32 0
  %33 = getelementptr inbounds [30 x i46], ptr %32, i64 0, i64 0
  %34 = insertvalue { ptr, i64 } poison, ptr %33, 0
  %35 = insertvalue { ptr, i64 } %34, i64 30, 1
  %36 = extractvalue { ptr, i64 } %35, 0
  %37 = extractvalue { ptr, i64 } %35, 1
  call fastcc void @sort.heap__anon_18649(ptr %0, ptr nonnull align 8 %36, i64 %37)
  store i64 0, ptr %18, align 8
  br label %Loop1

Loop:                                             ; preds = %Block1, %TryCont
  %38 = load i64, ptr %21, align 8
  %39 = icmp ult i64 %38, 30
  br i1 %39, label %Then, label %Else

Block1:                                           ; preds = %Block5
  %40 = add nuw i64 %38, 1
  store i64 %40, ptr %21, align 8
  br label %Loop

Then:                                             ; preds = %Loop
  store i64 %38, ptr %20, align 8
  %41 = extractvalue { ptr, i64 } %26, 1
  %42 = icmp ult i64 %38, %41
  br i1 %42, label %Then1, label %Else1

Else:                                             ; preds = %Loop
  br label %Block

Block2:                                           ; preds = %Block3, %Else1
  %43 = phi i4 [ %52, %Block3 ], [ 0, %Else1 ]
  store i4 %43, ptr %19, align 1
  %44 = load ptr, ptr %22, align 8
  %45 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(30,15,9)", ptr %44, i32 0, i32 0
  %46 = icmp ult i64 %38, 30
  br i1 %46, label %Then3, label %Else3

Then1:                                            ; preds = %Then
  %47 = extractvalue { ptr, i64 } %26, 1
  %48 = icmp ult i64 %38, %47
  br i1 %48, label %Then2, label %Else2

Else1:                                            ; preds = %Then
  br label %Block2

Block3:                                           ; preds = %Then2
  %49 = extractvalue { ptr, i64 } %26, 0
  %50 = getelementptr inbounds i4, ptr %49, i64 %38
  %51 = load i8, ptr %50, align 1
  %52 = trunc i8 %51 to i4
  br label %Block2

Then2:                                            ; preds = %Then1
  br label %Block3

Else2:                                            ; preds = %Then1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %38, i64 %47)
  unreachable

Block4:                                           ; preds = %Then3
  %53 = getelementptr inbounds [30 x i46], ptr %45, i64 0, i64 %38
  %54 = icmp ult i64 %38, 256
  br i1 %54, label %Then4, label %Else4

Then3:                                            ; preds = %Block2
  br label %Block4

Else3:                                            ; preds = %Block2
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %38, i64 30)
  unreachable

Block5:                                           ; preds = %Block6, %IntMaxOk
  br label %Block1

Then4:                                            ; preds = %Block4
  %55 = load i48, ptr %53, align 8
  %56 = zext i2 -1 to i48
  %57 = shl i48 %56, 12
  %58 = xor i48 %57, -1
  %59 = and i48 %55, %58
  %60 = zext i2 0 to i48
  %61 = shl i48 %60, 12
  %62 = or i48 %61, %59
  store i48 %62, ptr %53, align 8
  %63 = icmp ule i64 %38, 255
  br i1 %63, label %IntMaxOk, label %IntMaxFail

Else4:                                            ; preds = %Block4
  %64 = icmp eq i64 %38, 256
  br i1 %64, label %Then5, label %Else5

IntMaxFail:                                       ; preds = %Then4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk:                                         ; preds = %Then4
  %65 = trunc i64 %38 to i8
  store i8 %65, ptr %53, align 8
  %66 = load i48, ptr %53, align 8
  %67 = zext i4 -1 to i48
  %68 = shl i48 %67, 8
  %69 = xor i48 %68, -1
  %70 = and i48 %66, %69
  %71 = zext i4 %43 to i48
  %72 = shl i48 %71, 8
  %73 = or i48 %72, %70
  store i48 %73, ptr %53, align 8
  %74 = load i48, ptr %53, align 8
  %75 = zext i16 -1 to i48
  %76 = shl i48 %75, 14
  %77 = xor i48 %76, -1
  %78 = and i48 %74, %77
  %79 = zext i16 0 to i48
  %80 = shl i48 %79, 14
  %81 = or i48 %80, %78
  store i48 %81, ptr %53, align 8
  %82 = load i48, ptr %53, align 8
  %83 = zext i16 -1 to i48
  %84 = shl i48 %83, 30
  %85 = xor i48 %84, -1
  %86 = and i48 %82, %85
  %87 = zext i16 0 to i48
  %88 = shl i48 %87, 30
  %89 = or i48 %88, %86
  store i48 %89, ptr %53, align 8
  br label %Block5

Block6:                                           ; preds = %IntMaxOk1, %Then5
  br label %Block5

Then5:                                            ; preds = %Else4
  %90 = load i48, ptr %53, align 8
  %91 = zext i2 -1 to i48
  %92 = shl i48 %91, 12
  %93 = xor i48 %92, -1
  %94 = and i48 %90, %93
  %95 = zext i2 1 to i48
  %96 = shl i48 %95, 12
  %97 = or i48 %96, %94
  store i48 %97, ptr %53, align 8
  store i8 -1, ptr %53, align 8
  %98 = load i48, ptr %53, align 8
  %99 = zext i4 -1 to i48
  %100 = shl i48 %99, 8
  %101 = xor i48 %100, -1
  %102 = and i48 %98, %101
  %103 = zext i4 %43 to i48
  %104 = shl i48 %103, 8
  %105 = or i48 %104, %102
  store i48 %105, ptr %53, align 8
  %106 = load i48, ptr %53, align 8
  %107 = zext i16 -1 to i48
  %108 = shl i48 %107, 14
  %109 = xor i48 %108, -1
  %110 = and i48 %106, %109
  %111 = zext i16 0 to i48
  %112 = shl i48 %111, 14
  %113 = or i48 %112, %110
  store i48 %113, ptr %53, align 8
  %114 = load i48, ptr %53, align 8
  %115 = zext i16 -1 to i48
  %116 = shl i48 %115, 30
  %117 = xor i48 %116, -1
  %118 = and i48 %114, %117
  %119 = zext i16 0 to i48
  %120 = shl i48 %119, 30
  %121 = or i48 %120, %118
  store i48 %121, ptr %53, align 8
  br label %Block6

Else5:                                            ; preds = %Else4
  %122 = load i48, ptr %53, align 8
  %123 = zext i2 -1 to i48
  %124 = shl i48 %123, 12
  %125 = xor i48 %124, -1
  %126 = and i48 %122, %125
  %127 = zext i2 -2 to i48
  %128 = shl i48 %127, 12
  %129 = or i48 %128, %126
  store i48 %129, ptr %53, align 8
  %130 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %38, i64 257)
  %131 = extractvalue { i64, i1 } %130, 1
  br i1 %131, label %OverflowFail, label %OverflowOk

OverflowFail:                                     ; preds = %Else5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk:                                       ; preds = %Else5
  %132 = extractvalue { i64, i1 } %130, 0
  %133 = icmp ule i64 %132, 255
  br i1 %133, label %IntMaxOk1, label %IntMaxFail1

IntMaxFail1:                                      ; preds = %OverflowOk
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk1:                                        ; preds = %OverflowOk
  %134 = trunc i64 %132 to i8
  store i8 %134, ptr %53, align 8
  %135 = load i48, ptr %53, align 8
  %136 = zext i4 -1 to i48
  %137 = shl i48 %136, 8
  %138 = xor i48 %137, -1
  %139 = and i48 %135, %138
  %140 = zext i4 %43 to i48
  %141 = shl i48 %140, 8
  %142 = or i48 %141, %139
  store i48 %142, ptr %53, align 8
  %143 = load i48, ptr %53, align 8
  %144 = zext i16 -1 to i48
  %145 = shl i48 %144, 14
  %146 = xor i48 %145, -1
  %147 = and i48 %143, %146
  %148 = zext i16 0 to i48
  %149 = shl i48 %148, 14
  %150 = or i48 %149, %147
  store i48 %150, ptr %53, align 8
  %151 = load i48, ptr %53, align 8
  %152 = zext i16 -1 to i48
  %153 = shl i48 %152, 30
  %154 = xor i48 %153, -1
  %155 = and i48 %151, %154
  %156 = zext i16 0 to i48
  %157 = shl i48 %156, 30
  %158 = or i48 %157, %155
  store i48 %158, ptr %53, align 8
  br label %Block6

Block7:                                           ; preds = %Else6
  store i16 0, ptr %16, align 2
  store i16 0, ptr %15, align 2
  store i64 0, ptr %14, align 8
  %159 = load ptr, ptr %22, align 8
  %160 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(30,15,9)", ptr %159, i32 0, i32 0
  br label %Loop2

Loop1:                                            ; preds = %Block8, %Block
  %161 = load i64, ptr %18, align 8
  %162 = icmp ult i64 %161, 512
  br i1 %162, label %Then6, label %Else6

Block8:                                           ; preds = %Block9
  %163 = add nuw i64 %161, 1
  store i64 %163, ptr %18, align 8
  br label %Loop1

Then6:                                            ; preds = %Loop1
  store i64 %161, ptr %17, align 8
  %164 = load ptr, ptr %22, align 8
  %165 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(30,15,9)", ptr %164, i32 0, i32 1
  %166 = icmp ult i64 %161, 512
  br i1 %166, label %Then7, label %Else7

Else6:                                            ; preds = %Loop1
  br label %Block7

Block9:                                           ; preds = %Then7
  %167 = getelementptr inbounds [512 x i46], ptr %165, i64 0, i64 %161
  store i46 0, ptr %167, align 8
  br label %Block8

Then7:                                            ; preds = %Then6
  br label %Block9

Else7:                                            ; preds = %Then6
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %161, i64 512)
  unreachable

Block10:                                          ; preds = %Then11, %Else8
  ret i16 0

Loop2:                                            ; preds = %Block11, %Block7
  %168 = load i64, ptr %14, align 8
  %169 = icmp ult i64 %168, 30
  br i1 %169, label %Then8, label %Else8

Block11:                                          ; preds = %Block15, %Then9
  %170 = add nuw i64 %168, 1
  store i64 %170, ptr %14, align 8
  br label %Loop2

Then8:                                            ; preds = %Loop2
  %171 = getelementptr inbounds [30 x i46], ptr %160, i64 0, i64 %168
  store ptr %171, ptr %13, align 8
  store ptr %171, ptr %12, align 8
  store i64 %168, ptr %11, align 8
  %172 = load i48, ptr %171, align 8
  %173 = lshr i48 %172, 8
  %174 = trunc i48 %173 to i4
  %175 = icmp eq i4 %174, 0
  br i1 %175, label %Then9, label %Else9

Else8:                                            ; preds = %Loop2
  br label %Block10

Block12:                                          ; preds = %Else9
  %176 = load ptr, ptr %13, align 8
  %177 = load i16, ptr %16, align 2
  %178 = load i48, ptr %176, align 8
  %179 = zext i16 -1 to i48
  %180 = shl i48 %179, 14
  %181 = xor i48 %180, -1
  %182 = and i48 %178, %181
  %183 = zext i16 %177 to i48
  %184 = shl i48 %183, 14
  %185 = or i48 %184, %182
  store i48 %185, ptr %176, align 8
  %186 = load i16, ptr %16, align 2
  %187 = load i48, ptr %171, align 8
  %188 = lshr i48 %187, 8
  %189 = trunc i48 %188 to i4
  %190 = call { i4, i1 } @llvm.usub.with.overflow.i4(i4 -1, i4 %189)
  %191 = extractvalue { i4, i1 } %190, 1
  br i1 %191, label %OverflowFail1, label %OverflowOk1

Then9:                                            ; preds = %Then8
  br label %Block11

Else9:                                            ; preds = %Then8
  br label %Block12

OverflowFail1:                                    ; preds = %Block12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk1:                                      ; preds = %Block12
  %192 = extractvalue { i4, i1 } %190, 0
  %193 = zext i4 %192 to i16
  %194 = shl i16 1, %193
  %195 = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %186, i16 %194)
  %196 = extractvalue { i16, i1 } %195, 1
  br i1 %196, label %OverflowFail2, label %OverflowOk2

OverflowFail2:                                    ; preds = %OverflowOk1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk2:                                      ; preds = %OverflowOk1
  %197 = extractvalue { i16, i1 } %195, 0
  store i16 %197, ptr %10, align 2
  %198 = zext i4 6 to i16
  %199 = lshr i16 %197, %198
  store i16 %199, ptr %9, align 2
  %200 = icmp ugt i16 %199, 512
  br i1 %200, label %Then10, label %Else10

Block13:                                          ; preds = %Else11
  %201 = load i48, ptr %171, align 8
  %202 = lshr i48 %201, 8
  %203 = trunc i48 %202 to i4
  %204 = icmp ule i4 %203, -7
  br i1 %204, label %Then12, label %Else12

Block14:                                          ; preds = %Else10, %Then10
  %205 = phi i1 [ true, %Then10 ], [ %207, %Else10 ]
  br i1 %205, label %Then11, label %Else11

Then10:                                           ; preds = %OverflowOk2
  br label %Block14

Else10:                                           ; preds = %OverflowOk2
  %206 = load i16, ptr %15, align 2
  %207 = icmp uge i16 %206, 512
  br label %Block14

Then11:                                           ; preds = %Block14
  br label %Block10

Else11:                                           ; preds = %Block14
  br label %Block13

Block15:                                          ; preds = %IntMaxOk2, %Block16
  store i16 %199, ptr %15, align 2
  store i16 %197, ptr %16, align 2
  br label %Block11

Then12:                                           ; preds = %Block13
  store i64 0, ptr %8, align 8
  %208 = load i16, ptr %15, align 2
  %209 = zext i16 %208 to i64
  %210 = zext i16 %199 to i64
  %211 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %210, i64 %209)
  %212 = extractvalue { i64, i1 } %211, 1
  br i1 %212, label %OverflowFail3, label %OverflowOk3

Else12:                                           ; preds = %Block13
  %213 = load ptr, ptr %22, align 8
  %214 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(30,15,9)", ptr %213, i32 0, i32 1
  %215 = load i16, ptr %15, align 2
  %216 = zext i16 %215 to i64
  %217 = icmp ult i64 %216, 512
  br i1 %217, label %Then15, label %Else15

OverflowFail3:                                    ; preds = %Then12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk3:                                      ; preds = %Then12
  %218 = extractvalue { i64, i1 } %211, 0
  br label %Loop3

Block16:                                          ; preds = %Else13
  br label %Block15

Loop3:                                            ; preds = %Block17, %OverflowOk3
  %219 = load i64, ptr %8, align 8
  %220 = icmp ult i64 %219, %218
  br i1 %220, label %Then13, label %Else13

Block17:                                          ; preds = %Block18
  %221 = add nuw i64 %219, 1
  store i64 %221, ptr %8, align 8
  br label %Loop3

Then13:                                           ; preds = %Loop3
  %222 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %209, i64 %219)
  %223 = extractvalue { i64, i1 } %222, 1
  br i1 %223, label %OverflowFail4, label %OverflowOk4

Else13:                                           ; preds = %Loop3
  br label %Block16

OverflowFail4:                                    ; preds = %Then13
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"(ptr %0)
  unreachable

OverflowOk4:                                      ; preds = %Then13
  %224 = extractvalue { i64, i1 } %222, 0
  store i64 %224, ptr %7, align 8
  %225 = load ptr, ptr %22, align 8
  %226 = getelementptr inbounds %"compress.flate.Decompress.HuffmanDecoder(30,15,9)", ptr %225, i32 0, i32 1
  %227 = icmp ult i64 %224, 512
  br i1 %227, label %Then14, label %Else14

Block18:                                          ; preds = %Then14
  %228 = getelementptr inbounds [512 x i46], ptr %226, i64 0, i64 %224
  %229 = load i64, ptr %171, align 8
  %230 = trunc i64 %229 to i46
  store i46 %230, ptr %228, align 8
  br label %Block17

Then14:                                           ; preds = %OverflowOk4
  br label %Block18

Else14:                                           ; preds = %OverflowOk4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %224, i64 512)
  unreachable

Block19:                                          ; preds = %Then15
  %231 = getelementptr inbounds [512 x i46], ptr %214, i64 0, i64 %216
  store ptr %231, ptr %6, align 8
  store ptr %231, ptr %5, align 8
  %232 = load i48, ptr %231, align 8
  %233 = lshr i48 %232, 30
  %234 = trunc i48 %233 to i16
  store i16 %234, ptr %4, align 2
  %235 = load ptr, ptr %6, align 8
  %236 = icmp ule i64 %168, 65535
  br i1 %236, label %IntMaxOk2, label %IntMaxFail2

Then15:                                           ; preds = %Else12
  br label %Block19

Else15:                                           ; preds = %Else12
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).outOfBounds"(ptr %0, i64 %216, i64 512)
  unreachable

IntMaxFail2:                                      ; preds = %Block19
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"(ptr %0)
  unreachable

IntMaxOk2:                                        ; preds = %Block19
  %237 = trunc i64 %168 to i16
  %238 = load i48, ptr %235, align 8
  %239 = zext i16 -1 to i48
  %240 = shl i48 %239, 30
  %241 = xor i48 %240, -1
  %242 = and i48 %238, %241
  %243 = zext i16 %237 to i48
  %244 = shl i48 %243, 30
  %245 = or i48 %244, %242
  store i48 %245, ptr %235, align 8
  %246 = load ptr, ptr %13, align 8
  %247 = load i48, ptr %246, align 8
  %248 = zext i16 -1 to i48
  %249 = shl i48 %248, 30
  %250 = xor i48 %249, -1
  %251 = and i48 %247, %250
  %252 = zext i16 %234 to i48
  %253 = shl i48 %252, 30
  %254 = or i48 %253, %251
  store i48 %254, ptr %246, align 8
  br label %Block15
}

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.readFixedCode(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i7 @llvm.bitreverse.i7(i7) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i7, i1 } @llvm.usub.with.overflow.i7(i7, i7) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i2 @llvm.bitreverse.i2(i2) #1

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.peekBitsEnding__anon_18866(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.peekBits__anon_18860(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.takeBitsRuntime(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8, i4)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.decodeLength(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Token.matchLength(ptr noalias nonnull sret(%compress.flate.Token.MatchLength), ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.decodeDistance(ptr noalias nonnull sret({ i16, i16 }), ptr nonnull, ptr nonnull align 8, i8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Token.matchDistance(ptr noalias nonnull sret(%compress.flate.Token.MatchDistance), ptr nonnull, i8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @compress.flate.Decompress.writeMatch(ptr nonnull, ptr nonnull align 8, i16, i16)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.writableSlicePreserve(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.peekBitsEnding__anon_18929(ptr noalias nonnull sret({ i15, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.peekBits__anon_18923(ptr noalias nonnull sret({ i15, i16 }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"compress.flate.Decompress.HuffmanDecoder(286, 15, 9).find"(ptr noalias nonnull sret({ i46, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i16)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.decodeSymbol__anon_18911(ptr noalias nonnull sret({ i46, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i15 @llvm.bitreverse.i15(i15) #1

; Function Attrs: nounwind uwtable
declare fastcc void @"compress.flate.Decompress.HuffmanDecoder(30, 15, 9).find"(ptr noalias nonnull sret({ i46, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i16)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.decodeSymbol__anon_18944(ptr noalias nonnull sret({ i46, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i2 @compress.flate.Container.Metadata.container(ptr nonnull, ptr nonnull readonly align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeStructPointer__anon_18452(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeArray__anon_18463(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Reader.discardAll(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.discardDelimiterInclusive(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @__zig_is_named_enum_value_compress.flate.Decompress.BlockType(i2)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.alignBitsDiscarding(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @"__zig_is_named_enum_value_@typeInfo(compress.flate.Decompress.State).@\22union\22.tag_type.?"(i4)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.writableSliceGreedyPreserve(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @Io.Limit.min(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.readVec(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.advance(ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.writeBytePreserve(ptr nonnull, ptr nonnull align 8, i64, i8)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i5 @llvm.bitreverse.i5(i5) #1

; Function Attrs: nounwind uwtable
declare fastcc i1 @__zig_is_named_enum_value_compress.flate.Decompress.Symbol.Kind(i2)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeArray__anon_18964(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.alignBitsPreserving(ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.takeArray__anon_18973(ptr noalias nonnull sret({ ptr, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.discardShort(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.discardDelimiterLimit(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @mem.readVarInt__anon_18995(ptr nonnull, ptr nonnull readonly align 1, i64, i1)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.heapContext__anon_19040(ptr nonnull, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.rebase(ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.peekGreedy(ptr noalias nonnull sret({ { ptr, i64 }, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.siftDown__anon_19243(ptr nonnull, i64, i64, i64, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @sort.heap__anon_18649.Context.swap(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i1 @sort.heap__anon_18649.Context.lessThan(ptr nonnull, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @mem.swap__anon_19266(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc i1 @compress.flate.Decompress.Symbol.asc(ptr nonnull, i46, i46)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.streamIndirect(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @compress.flate.Decompress.discardIndirect(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged(Build.InitializedDepKey, *Build.Dependency, Build.InitializedDepContext, 80).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.SystemLibraryMode,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged([]const u8, []const u8, process.EnvMap.EnvNameHashContext, 80).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,void,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u32,void,array_hash_map.AutoContext(u32),false).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4, ptr nonnull align 1, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u32,void,array_hash_map.AutoContext(u32),false).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4, ptr nonnull align 1, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged([]const u8, Build.UserInputOption, hash_map.StringContext, 80).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged([]const u8, Build.AvailableOption, hash_map.StringContext, 80).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,*Build.TopLevelStep,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,*Build.TopLevelStep,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,*Build.Module,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,*Build.Module,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,*Build.Step.WriteFile,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,*Build.Step.WriteFile,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.LazyPath,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.LazyPath,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.Step.ConfigHeader.Value,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.Step.ConfigHeader.Value,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.Module.LinkFrameworkOptions,array_hash_map.StringContext,true).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged([]const u8,Build.Module.LinkFrameworkOptions,array_hash_map.StringContext,true).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged([]const u8, void, hash_map.StringContext, 80).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,Build.Fuzz.CoverageMap,array_hash_map.AutoContext(u64),false).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(u64,Build.Fuzz.CoverageMap,array_hash_map.AutoContext(u64),false).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(debug.Coverage.String,void,debug.Coverage.String.MapContext,false).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4, ptr nonnull align 1, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(debug.Coverage.String,void,debug.Coverage.String.MapContext,false).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4, ptr nonnull align 1, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(debug.Coverage.File,void,debug.Coverage.File.MapContext,false).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4, ptr nonnull align 1, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(debug.Coverage.File,void,debug.Coverage.File.MapContext,false).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 4, ptr nonnull align 1, ptr nonnull align 4)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(Build.Cache.Path,array_list.Aligned([]const u8,null),Build.Cache.Path.TableAdapter,false).Data).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @"multi_array_list.MultiArrayList(array_hash_map.ArrayHashMapUnmanaged(Build.Cache.Path,array_list.Aligned([]const u8,null),Build.Cache.Path.TableAdapter,false).Data).Slice.dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 1, ptr nonnull align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.drain(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(u8, null).ensureUnusedCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"array_list.Aligned(u8, null).appendSliceAssumeCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Writer.Allocating.sendFile(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc { ptr, i64 } @"array_list.Aligned(u8, null).unusedCapacitySlice"(ptr nonnull, ptr nonnull readonly align 8)

; Function Attrs: nounwind uwtable
declare fastcc void @Io.Reader.readSliceShort(ptr noalias nonnull sret({ i64, i16, [6 x i8] }), ptr nonnull, ptr nonnull align 8, ptr nonnull align 1, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @Io.Writer.Allocating.growingRebase(ptr nonnull, ptr nonnull align 8, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(u8, null).ensureTotalCapacity"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc i64 @"array_list.Aligned(u8, null).growCapacity"(ptr nonnull, i64, i64)

; Function Attrs: nounwind uwtable
declare fastcc i16 @"array_list.Aligned(u8, null).ensureTotalCapacityPrecise"(ptr nonnull, ptr nonnull align 8, ptr nonnull readonly align 8, i64)

; Function Attrs: nounwind uwtable
declare fastcc void @"hash_map.HashMapUnmanaged([]const u8, *const Build.UserValue, hash_map.StringContext, 80).dbHelper"(ptr nonnull, ptr nonnull align 8, ptr nonnull align 8, ptr nonnull align 8)

attributes #0 = { nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { cold noreturn nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { noinline nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #7 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #8 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #9 = { naked nosanitize_coverage nounwind skipprofile uwtable "frame-pointer"="none" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #10 = { cold noreturn nounwind null_pointer_is_valid uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #11 = { noreturn nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #12 = { cold noreturn nounwind memory(inaccessiblemem: write) }
attributes #13 = { cold nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #14 = { naked noreturn nosanitize_coverage nounwind skipprofile uwtable "frame-pointer"="none" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #15 = { noinline }


