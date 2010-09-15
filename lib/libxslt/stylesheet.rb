module LibXSLT
  module XSLT
    class Stylesheet
      # options to be used for parsing stylesheets
      PARSE_OPTIONS = LibXML::XML::Parser::Options::NOCDATA | LibXML::XML::Parser::Options::NOENT
      class << self
        # create a xslt stylesheet from a string
        def string(xml)
          doc = LibXML::XML::Parser.string(xml, :options => PARSE_OPTIONS).parse
          return new(doc)
        end
        # create a xslt stylesheet from a file specified by its filename
        def file(filename)
          doc = LibXML::XML::Parser.file(filename, :options => PARSE_OPTIONS).parse
          return new(doc)
        end
        # create a xslt stylesheet from an io object
        def io(io_object)
          doc = LibXML::XML::Parser.io(io_object, :options => PARSE_OPTIONS).parse
          return new(doc)
        end
      end
      # transform a xml to a string
      def transform_to_string(doc)
        rdoc = apply(doc)
        return dump_result(rdoc)
      end
      # transform a xml to a file (specified by an output stream)
      def transform_to_file(doc, io = STDOUT)
        rdoc = apply(doc)
        return save_result(rdoc, io)
      end
    end
  end
end
