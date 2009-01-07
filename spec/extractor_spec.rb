$: << File.dirname(__FILE__) + '/../lib'
require 'tmpdir'
require 'pdf/extractor'
require 'rubygems'
require 'pdf/writer'

describe 'an opened PDF document', :shared => true do
	before do
		pdf = PDF::Writer.new(:paper => 'A4')

		pdf.text 'Hello world!', :font_size => 32, :justification => :center
		pdf.start_new_page
		pdf.select_font 'Times-Bold'
		pdf.text 'Hello again!', :font_size => 18, :justification => :center
		pdf.start_new_page
		pdf.select_font 'Times-Italic'
		pdf.text 'Hello once again!', :font_size => 18, :justification => :center

		@pdf_filename = File.join(Dir.tmpdir, 'test.pdf')
		pdf.save_as @pdf_filename
		@document = PDF::Extractor.open(@pdf_filename)
	end

	after do
		File.delete @pdf_filename
	end
end

describe 'A document' do
	it_should_behave_like 'an opened PDF document'
	before{ @it = @document }

	it 'has pages' do
		@it.pages.length.should == 3
	end

	it 'has elements' do
		@it.elements.length.should == 3
	end
end

describe 'A page' do
	it_should_behave_like 'an opened PDF document'
	before{ @it = @document.pages.first }

	it 'has a width and a height' do
		@it.width.should  == 595
		@it.height.should == 841
	end
end

describe 'An element' do
	it_should_behave_like 'an opened PDF document'
	before{ @page = @document.pages.first; @it = @page.elements.first }

	it 'has a position on a page' do
		@it.left.should be_between(0, @page.width / 2) # the text is centered
		@it.top.should  be_between(30, 60)
	end

	it 'has a width and a height' do
		@it.width.should  be_between(150, 180)
		@it.height.should be_between(20, 40)
	end

	it 'has content' do
		@it.content.should == 'Hello world!'
	end
end

describe 'An italic element' do
	it_should_behave_like 'an opened PDF document'
	before{ @page = @document.pages[2]; @it = @page.elements.first }

	it 'has content' do
		@it.content.should == 'Hello once again!'
	end
end


describe 'A bold element' do
	it_should_behave_like 'an opened PDF document'
	before{ @page = @document.pages[1]; @it = @page.elements.first }

	it 'has content' do
		@it.content.should == 'Hello again!'
	end
end

describe 'A font' do
	it_should_behave_like 'an opened PDF document'
	before{ @it = @document.elements.first.font }

	it 'has a name' do
		@it.name.should == 'Helvetica'
	end

	it 'has a size' do
		@it.size.should == 32
	end
end

describe 'A bold font' do
	it_should_behave_like 'an opened PDF document'
	before{ @it = @document.elements[1].font }

	it 'has a name' do
		@it.name.should == 'Times'
	end

	it 'is bold' do
		@it.should be_bold
	end
end

describe 'An italic font' do
	it_should_behave_like 'an opened PDF document'
	before{ @it = @document.elements[2].font }

	it 'has a name' do
		@it.name.should == 'Times'
	end

	it 'is italic' do
		@it.should be_italic
	end
end

describe 'A malformed PDF document' do
	before { File.open(@filename = File.join(Dir.tmpdir, 'bogus.pdf'), 'w'){|f| f.print 'Foo'} }
	after  { File.delete @filename }

	it 'should raise MalformedPDFError' do
		lambda do
			PDF::Extractor.open(@filename)
		end.should raise_error(PDF::Extractor::MalformedPDFError)
	end
end

describe 'A non-readable PDF document' do
	it 'should raise RuntimeError' do
		lambda do
			PDF::Extractor.open('this_file_should_not_exist')
		end.should raise_error(RuntimeError)
	end
end
