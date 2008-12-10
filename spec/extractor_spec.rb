$: << File.dirname(__FILE__) + '/../lib'
require 'tmpdir'
require 'pdf/extractor'
require 'rubygems'
require 'pdf/writer'

describe 'Extracting a PDF document' do
	before do
		pdf = PDF::Writer.new(:paper => 'A4')

		pdf.text 'Hello world!', :font_size => 32, :justification => :center
		pdf.start_new_page
		pdf.text 'Hello again!', :font_size => 18, :justification => :center

		@pdf_filename = File.join(Dir.tmpdir, 'test.pdf')
		pdf.save_as @pdf_filename
		@document = PDF::Extractor.open(@pdf_filename)
	end
		
	it 'should get the width and height of the document' do
		@document.width.should == 595
		@document.height.should == 841
	end

	it 'should get the contents' do
		@document.elements[0].content.should == 'Hello world!'
		@document.elements[1].content.should == 'Hello again!'
	end

	it 'should get the contents within a certain page' do
		@document.pages[0].elements[0].content.should == 'Hello world!'
		@document.pages[1].elements[0].content.should == 'Hello again!'
	end

	it 'should get the font name and font size of an element' do
		@document.elements[0].font.name.should == 'Helvetica'
		@document.elements[0].font.size.should == 32
	end

	it 'should get the position of an element' do
		@document.elements[0].left.should be_between(0, @document.width / 2) # the text is centered
		@document.elements[0].top.should be_between(30, 60)
	end

	it 'should get the width and height of an element' do
		@document.elements[0].width.should be_between(150, 180)
		@document.elements[0].height.should be_between(20, 40)
	end

	after do
		File.delete @pdf_filename
	end
end

describe 'Reading a malformed PDF document' do
	it 'should raise MalformedPDFError if the PDF is malformed' do
		filename = File.join(Dir.tmpdir, 'bogus.pdf')
		File.open(filename, 'w'){|f| f.print 'Foo'}
		lambda do
			PDF::Extractor.open(filename)
		end.should raise_error(PDF::Extractor::MalformedPDFError)
		File.delete filename
	end
end

describe 'Reading a non-readable PDF document' do
	it 'should raise RuntimeError if the PDF is not readable or not existing' do
		lambda do
			PDF::Extractor.open('this_file_should_not_exist')
		end.should raise_error(RuntimeError)
	end
end
