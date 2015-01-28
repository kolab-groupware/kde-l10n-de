#!/usr/bin/ruby
# Ruby 1.8.7 or higher is required
#
# Author: Alexander Potashev <aspotashev@gmail.com>

# Usage:
#   ./opensrc_generate_list.rb         
#                         -- generates opensrc_list.py for all sources in /home
#                         (i.e. default file list generator is global-home)
#   ./opensrc_generate_list.rb [GENERATOR1] [GENERATOR2] ...
#                         -- generates opensrc_list.py for all files listed by specified
#                         file list generators. The order of generators defines their
#                         priorities. The first generator has the highest priority,
#                         it means that the files it generates are preferred over
#                         other files when the package names are identical.


$generator_list = {
	'kde-trunk'   => lambda { `find ../../../ -iname Messages.sh`.split("\n") },
	'kde'         => lambda { `find ../../../KDE -iname Messages.sh`.split("\n") },
	'global-home' => lambda { `locate -r ^/home/.*/Messages.sh$`.split("\n") },
	'global-root' => lambda { `locate -r /Messages.sh$`.split("\n") },
}
$generator_list.default = lambda do
	raise "Missing file list generator"
end

# fn: Messages.sh file path
# Return value: array containing names of templates (.pot), e.g. "kio4", "akonadi_filter_console", ...
def extract_destinations(fn)
	cont = File.open(fn) {|f| f.read }
	m = cont.scan(/\$podir\/([a-zA-Z0-9_\.\-]+)\.pot/) +
    cont.scan(/\$\{podir\}\/([a-zA-Z0-9_\.\-]+)\.pot/) +
		cont.scan(/\$\{podir:\-\.\}\/([a-zA-Z0-9_\.\-]+)\.pot/) +
    cont.scan(/po\/([a-zA-Z0-9_\.\-]+)\.pot/) +
		cont.scan(/\.\.\/po\/([a-zA-Z0-9_\.\-]+).pot/)
  m = m.map(&:first).uniq

	if m.empty?
		if cont.split("\n").all? {|s| s[0..0] == '#' or s == 'true' or s.empty? }
			# file contains only comments, skipping
		elsif File.dirname(fn).match(/((\/sample_project$)|(kapptemplate\/templates\/C\+\+\/[a-z0-9]+(\/src)?$))/)
			# part of an example, skipping
		elsif cont.match(/ (\$\{podir\}\/)?\$\{PROJECT\}\.pot/) and m = cont.match(/^PROJECT=\"([a-zA-Z0-9_\.\-]+)\"/)
			# some people like memorizing constants ;)
			m = [m[1]]
		else
			puts "ERROR: Unhandled file #{fn}"
		end
	end

  m.compact
end

def extract_destinations_cached(fn)
	(@cache ||= {})[File.expand_path(fn)] ||= extract_destinations(fn)
end

# generator: name of generator, e.g. "kde-trunk"
# Return value: array of pairs [pot_name, source_dir]
def generate_mappings(generator)
  r = []
  $generator_list[generator][].each do |fn|
    d = extract_destinations_cached(fn)
    d.each do |path|
      r << [path, File.dirname(fn).sub(/^(\.\.\/){3}/, '')]
    end
  end

  r
end

Array.class_eval do
	def to_hash_take_first
		self.inject({}) do |h,pair|
			h[pair[0]] = pair[1] if not h.has_key?(pair[0])
			h
		end
	end

	def flatten_by_one_level
		self.inject(&:+)
	end
end

#---------------------------------------------------------------------------

gen_try_list = ARGV.size > 0 ? ARGV : ['global-home']  # search via "locate" in "/home/" by default


f = File.open('opensrc_list.py', 'w')
f.puts 'mapSrc = {'

gen_try_list.map {|g| generate_mappings(g) }.flatten_by_one_level.to_hash_take_first.sort.each do |key,value|
	f.puts "    '#{key}': '#{value}',"
end

f.puts '}'
f.close

