require "tmpdir"

Before do

	@old_dir = Dir.pwd
	@temp_dir = Dir.mktmpdir
	Dir.chdir @temp_dir

end

After do

	FileUtils.remove_entry_secure @temp_dir
	Dir.chdir @old_dir

end
