#!/usr/bin/ruby
# coding: utf-8

# Copyright (C) 2010-2011 by WU Jun <quark@lihdd.net>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'fileutils'
require 'digest'
require 'term/ansicolor'

# extend String class
class String
  include Term::ANSIColor
end

# constants
BASE_PATH = ARGV[0] || ENV['BASE_PATH'] || Dir.pwd
OUTPUT_PATH = File.expand_path(ENV['OUTPUT_PATH'] || "#{BASE_PATH}/../build")
OUTPUT_FILE = ENV['OUTPUT_FILE'] || 'output' # .tex
PAGE_FOOTER = ENV['PAGE_FOOTER'] || '{\bfseries Routine Library} $\mid$ Zhejiang University ICPC Team'
CHARS_PER_LINE = (ENV['CHARS_PER_LINE'] || 88).to_i # 112 if scriptsize
MAIN_FONT = ENV['MAIN_FONT'] || 'TeX Gyre Pagella'
CJK_FONT = ENV['CJK_FONT'] || 'Adobe 黑体 Std'
MONO_FONT = ENV['MONO_FONT'] || 'Consolas'

TRANSLATES = { 
  '几何' => 'Geometry',
  '组合' => 'Permutation',
  '结构' => 'Structures',
  '数论' => 'Number Theory',
  '数值计算' => 'Numerical',
  '数值' => 'Numerical',
  '图论_NP搜索' => 'Graph_NP Searching',
  '图论_匹配' => 'Graph_Matching',
  '图论_应用' => 'Graph_Applications',
  '图论_最短路' => 'Graph_Shortest Path',
  '图论_生成树' => 'Graph_Spanning Tree',
  '图论_网络流' => 'Graph_Network Flow',
  '图论_连通性' => 'Graph_Connectivity',
  '应用' => 'Applications',
  '其他' => 'Others',
  '附录_应用' => 'Appendix_Applications',
  '附录_结构' => 'Appendix_Structures',
}

# print basic information
puts "\nREQUIRED PROGRAMS:".green.bold
[ :pygmentize, :xelatex, :astyle, :'fc-match' ].each do |p|
  print "#{p.to_s.bold} => "
  found = system("which #{p}")
  raise "Required Program missing: #{p}" if not found
end

puts "\nPARAMETERS:".green.bold
[ :BASE_PATH, :OUTPUT_PATH, :OUTPUT_FILE, :PAGE_FOOTER, :CHARS_PER_LINE, :MAIN_FONT, :CJK_FONT, :MONO_FONT ].each { |p| puts "#{p.to_s.bold} = #{eval p.to_s}" }

puts "\nREQUIRED FONTS:".green.bold
[ MAIN_FONT, CJK_FONT, MONO_FONT ].each do |f|
  fc_match = `fc-match '#{f}'`
  print "#{f.to_s.bold} => "
  if fc_match.include?(f)
    puts fc_match
  else
    puts fc_match
    puts "Not found".red.bold
    raise "Font missing: #{f}"
  end
end

# prepare output dir
FileUtils.mkdir_p OUTPUT_PATH

# prepare pygments tex theme, with minor changes:
# - add underline for numbers
# - add background to comments
pygment_style = `pygmentize -S emacs -f latex`
# For pygments 1.4
pygment_style.gsub! '\def\PY@tok@m{', '\0\let\PY@ul=\underline'
pygment_style.gsub! '\def\PY@tok@c{\let\PY@it=\textit\def\PY@tc##1{\textcolor[rgb]{0.00,0.53,0.00}{##1}}', '\0\def\PY@bc##1{\colorbox[rgb]{0.80,0.95,0.85}{##1}}'
pygment_style.gsub! '\def\PY@tok@cp{\def\PY@tc##1{\textcolor[rgb]{0.00,0.53,0.00}{##1}}', '\0\def\PY@bc##1{\colorbox[rgb]{1.0,1.0,1.0}{##1}}'
# For pygments 1.6
pygment_style.gsub! 'PY@tok@m\endcsname{', '\0\let\PY@ul=\underline'
pygment_style.gsub! /(PY@tok@c[m1]\\endcsname{.*)(\\textcolor.*})$/, '\1\colorbox[rgb]{0.80,0.95,0.85}{\strut\2}'

File.open("#{OUTPUT_PATH}/pygments.tex", 'w') { |f| f.puts pygment_style }

# prepare tex file
$tex_file = File.open "#{OUTPUT_PATH}/#{OUTPUT_FILE}.tex", 'w'
$last_chapter_title = ''
$sha1_hasher = Digest::SHA1.new
$hashed = {}

def simple_hash(str)
  $sha1_hasher.reset
  $sha1_hasher.update str
  result = $sha1_hasher.to_s
  raise "Hash Conflict! (#{result})" if $hashed[result]
  $hashed[result] = true
  result
end

def line_wrap(file)
  wrapped_content = ''
  File.open(file, 'r:utf-8') do |file|
    file.each_line do |line|
      line.gsub! "\t", '    '
      chars_in_line = 0
      line.each_char do |ch|
        next if ch == "\n"
        chars_in_line = chars_in_line + (ch.ascii_only? ? 1 : 2)
        if chars_in_line > CHARS_PER_LINE
          wrapped_content << "\\\n"
          chars_in_line = 1
        end
        wrapped_content << ch
      end
      wrapped_content << "\n"
    end
  end
  File.open(file, 'w:utf-8') { |file| file.write wrapped_content }
end

def process_file(file, type)
  # copy it to build directory (will rewrite existed)
  basename = "#{simple_hash(file)}"
  puts "#{'Processing'.bold} #{type.to_s.yellow} #{File.basename(file)} => #{basename.cyan}"

  # special handle pdf files
  if type == :pdf
    output_file = "#{OUTPUT_PATH}/#{basename}.pdf"
    File.link file, output_file unless File.exist?(output_file)
    # direct insert that pdf into
    $tex_file.write '\includepdf[pagecommand=\thispagestyle{fancy},scale=0.95,pages=-]{' + "#{basename}}\n"
    return
  end
  
  output_file = "#{OUTPUT_PATH}/#{basename}.tex"

  # check timestamp to know if we need to process that file (again)
  should_process = if File.exist?(output_file)
    File.mtime(file) > File.mtime(output_file)
  else
    true
  end

  if should_process
    FileUtils.cp file, output_file

    # check encoding, convert gb18030 to utf8 if necessary
    if `file '#{output_file}'` =~ /ISO/
      # convert it to utf8
      puts "non utf-8, convert from gb18030..."
      ic = Iconv.new('UTF-8//IGNORE//TRANSLIT', 'GB18030')
      gbk_content = File.open(output_file, 'r:gb18030') { |file| file.read }
      File.open(output_file, 'w:utf-8') { |file| file.write(ic.iconv(gbk_content)) }
    end

    # processing related to type
    case type
    when :plain
      line_wrap output_file
    when :cpp, :java, :pas
      system "astyle -A2 -c -s4 -k3 -n '#{output_file}'" if [ :cpp, :java ].include? type
      line_wrap output_file
      raise 'Pygmentize Error' unless system "pygmentize -l #{type} -f latex -P encoding=utf-8 -o '#{output_file}.out' '#{output_file}'"
      FileUtils.mv "#{output_file}.out", output_file
    end
  else
    puts "not modified, skipped\n"
  end

  case type
  when :plain
    $tex_file.write "\\begin{Verbatim}[frame=none,numbers=none]\n"
    $tex_file.write File.open(output_file, 'r') { |f| f.read }
    $tex_file.write "\\end{Verbatim}\n"
  else
    $tex_file.write "{ \\include{#{basename}} }\n"
  end
end

def process_folder(folder, title = nil)
  return unless File.directory? "#{BASE_PATH}/#{folder}"

  title = folder[/[^\/]*$/] if not title
  puts "\n#{'PROCESSING FOLDER'.green.bold} #{folder}:\n#{'Title'.bold} = #{title}"

  subtitles = title.split '_'
  section_title = '\section'

  if $last_chapter_title != subtitles[0]
    $last_chapter_title = subtitles[0]
    $tex_file.puts "\\chapter{#{subtitles[0]}}"
  end

  if subtitles.length == 2
    $tex_file.puts "\\section{#{subtitles[1]}}"
    section_title = '\subsection'
  end

  # include plain txt files, tex files, then code files
  { '*.txt' => :plain, '*.tex' => :tex, '*.{cpp,cc,c}' => :cpp, '*.java' => :java, '*.pas' => :pas, '*.pdf' => :pdf }.each do |ext, type|
    Dir["#{BASE_PATH}/#{folder}/#{ext}"].sort.each do |file|
      $tex_file.puts "#{section_title}{#{File.basename(file, File.extname(file)).gsub(/_/, ' ')}}"
      process_file file, type
    end
  end
end

# write tex header
# tiny text version: twocolumn, tinysize, 71 chars per line
$tex_file.puts <<"HEAD_END"
\\documentclass[12pt,a4paper,twoside]{book}
\\usepackage{xunicode,xltxtra,fontspec,xeCJK}
\\usepackage{longtable,multirow,setspace,multicol}
\\usepackage[pdfborder=0 0 0]{hyperref}
\\usepackage{amsfonts,amsmath}
\\usepackage{pdfpages}
\\usepackage{fancyhdr,fancyvrb,color}
\\usepackage[top=1.0in, bottom=1.0in, left=0.8in, right=0.8in]{geometry}

\\setmainfont{#{MAIN_FONT}}
\\setCJKmainfont{#{CJK_FONT}}
\\setmonofont{#{MONO_FONT}}
\\XeTeXlinebreaklocale "zh"
\\XeTeXlinebreakskip = 0pt plus 1pt

\\pagestyle{fancy}
\\fancypagestyle{plain}
\\fancyhead{} % clear all header fields
\\fancyfoot{} % clear all footer fields
\\fancyhead[LO,RE]{\\scriptsize \\slshape \\leftmark}
\\fancyhead[LE,RO]{\\scriptsize \\rightmark}
\\fancyfoot[LE,RO]{\\thepage}
\\fancyfoot[LO]{{\\fontspec{#{MAIN_FONT}}\\scriptsize{#{PAGE_FOOTER}}}}
\\fancyfoot[RE]{{\\fontspec{#{MAIN_FONT}}\\scriptsize{\\today}}}
\\renewcommand{\\headrulewidth}{0.2pt}

\\let\\clearpage\\relax

\\newcommand{\\matharea}[1]{\\begin{displaymath}\\begin{split}#1\\end{split}\\end{displaymath}}

\\include{pygments}
\\RecustomVerbatimEnvironment{Verbatim}{Verbatim}{frame=leftline,rulecolor=\\color[rgb]{0.53,0.53,0.53},numbers=left,numbersep=2pt,fontsize=\\footnotesize}
\\begin{document}
\\tableofcontents
HEAD_END

# process builtin folders
TRANSLATES.each do |key, value|
  process_folder key # ,value # now use chinese titles
end

# process other folders
Dir.foreach BASE_PATH do |name|
  next if name[0] == '.' or TRANSLATES[name]
  next unless File.directory? "#{BASE_PATH}/#{name}"
  process_folder name
end

# finish and close tex file
$tex_file.puts <<'TAIL_END'
\cleardoublepage
\end{document}
TAIL_END
$tex_file.close

# build, run three times to generate correct table of contents
FileUtils.rm_f [ "#{OUTPUT_PATH}/#{OUTPUT_FILE}.pdf", "#{OUTPUT_PATH}/#{OUTPUT_FILE}.log" ]
Dir.chdir OUTPUT_PATH

puts "\nPROCESSING TEX:".green.bold
3.times do |n|
  puts "Executing xelatex (#{n+1}/3)..."
  unless system "xelatex -halt-on-error -interaction=errorstopmode #{OUTPUT_FILE}.tex < /dev/null > /dev/null 2> /dev/null"
    puts "\n#{'xelatex error'.red.bold}, please check xelatex log file in #{OUTPUT_PATH.bold}"
    raise 'Xelatex Error'
  end
end

puts "\nPDF GENERATED:".green.bold
puts "#{OUTPUT_PATH}/#{OUTPUT_FILE}.pdf"

