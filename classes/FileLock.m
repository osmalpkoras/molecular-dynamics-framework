classdef FileLock < handle
    properties
        Lock
        File
        FileChannel
        FilePath
    end

    methods
        function this = FileLock(filepath)
            this.FilePath = filepath;
            dir = fileparts(filepath);
            if ~isfolder(dir); mkdir(dir); end
            this.File = java.io.RandomAccessFile(this.FilePath,'rws');
            this.FileChannel = this.File.getChannel();
        end

        function lock(this)
            this.Lock = this.FileChannel.lock();
        end
        
        function tryLock(this)
            try
                this.Lock = this.FileChannel.tryLock();
            catch e
                Globals.log("File %s is already locked by this programm or the file/channel as been closed.", this.FilePath);
            end
        end
        
        function b = hasLock(this)
            b = ~isempty(this.Lock) && this.Lock.isValid();
        end

        function delete(this)
            this.release();
            this.File.close();
        end

        function release(this)
            if this.hasLock()
                this.Lock.release();
            end
        end
    end
end
