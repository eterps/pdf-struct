require 'rexml/document'
require 'rexml/streamlistener'

module PDF
	module Extractor
		class ConversionError   < RuntimeError; end
		class MalformedPDFError < RuntimeError; end

		def self.open(path)
			input = `pdftohtml -enc UTF-8 -xml -stdout '#{path}' 2>&1`
			case input
			#when /command not found/
			#	raise ConversionError, 'pdftohtml command not found'
			when /PDF file is damaged/
				raise MalformedPDFError, "the PDF with filename '#{path}' is malformed"
			when /Couldn't open file/
				raise RuntimeError, "Couldn't open file: '#{path}'"
			else
				PDF::Extractor::Document.new(input)
			end
		end
	end
end

class PDF::Extractor::Element
	attr_reader   :top, :left, :width, :height, :font
	attr_accessor :content

	def initialize(params = {})
		@top     = params[:top]
		@left    = params[:left]
		@width   = params[:width]
		@height  = params[:height]
		@font    = params[:font]
		@content = params[:content]
	end
end

class PDF::Extractor::Font
	attr_reader   :id, :name, :size
	attr_accessor :style

	def initialize(params = {})
		@id    = params[:id]
		@size  = params[:size].to_f
		@name  = params[:name]
		@style = :normal
	end

	def normal?; @style == :normal end
	def bold?;   @style == :bold   end
	def italic?; @style == :italic end
end

class PDF::Extractor::Page
	attr_reader :elements, :width, :height

	def initialize(params = {})
		@width    = params[:width]
		@height   = params[:height]
		@elements = []
	end
end

class PDF::Extractor::Reader
	include REXML::StreamListener

	attr_reader :pages, :fonts

	def initialize
		@pages, @fonts = [], []
	end

	def tag_start(name, attributes)
		@in_text = false
		case name
		when 'page'
			@pages << PDF::Extractor::Page.new(
				:width => attributes['width'].to_f,
				:height => attributes['height'].to_f
			)
		when 'fontspec'
			@fonts << PDF::Extractor::Font.new(
				:id => attributes['id'],
				:size => attributes['size'].to_f + 2, # is this right?
				:name => attributes['family']
			)
		when 'text'
			@in_text = true
			@pages.last.elements << PDF::Extractor::Element.new(
				:top => attributes['top'].to_f,
				:left => attributes['left'].to_f,
				:width => attributes['width'].to_f,
				:height => attributes['height'].to_f,
				:font => @fonts.find{|n| n.id == attributes['font']}
			)
		when 'b'
			@in_text = true
			@pages.last.elements.last.font.style = :bold
		when 'i'
			@in_text = true
			@pages.last.elements.last.font.style = :italic
		end
	end

	def text(str)
		@pages.last.elements.last.content = str if @in_text and str =~ /\S/
	end
end

class PDF::Extractor::Document
	attr_reader :pages

	def initialize(source)
		populate source
	end

	def elements; @pages.map{|n| n.elements}.flatten end

private

	def populate(source)
		listener = PDF::Extractor::Reader.new
		REXML::Parsers::StreamParser.new(source, listener).parse
		@pages, @fonts = listener.pages, listener.fonts
	end
end
