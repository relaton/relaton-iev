require "relaton"
require "relaton_iev/version"
require "htmlentities"
require "uuidtools"

module RelatonIev
  class Error < StandardError; end

  class << self
    IEVPATH = <<~IEV.strip.freeze
      //*[@citeas = 'IEC 60050:2011' or @citeas = 'IEC 60050:2011' or @citeas = 'IEC&#xa0;60050:2011' or @citeas = 'IEC&#xA0;60050:2011']
    IEV

    # converts generic IEV citation to citation of IEC 60050-n
    # assumes IEV citations are of form
    # <eref type="inline" bibitemid="a" citeas="IEC 60050">
    # <locality type="clause"><referenceFrom>101-01-01</referenceFrom>
    # </locality></eref>
    #
    # @param xmldoc [Nokogiri::XML::Documet]
    # @return [Set<String>]
    def links_iev2iec60050part(xmldoc)
      parts = Set.new
      xmldoc.xpath(IEVPATH).each do |x|
        m = x.at(".//locality[@type = 'clause']/referenceFrom")&.text
          &.sub(/^(\d+).*$/, "\\1") or next
        parts << m
        x["citeas"] = @c.decode(x["citeas"]).sub(/60050/, "60050-#{m}")
        x["bibitemid"] = "IEC60050-#{m}"
      end
      parts
    end

    # replace generic IEV reference with references to all extracted
    # IEV parts
    #
    # @param xml [Nokogiri::XML::Document]
    # @param parts [Set<String>]
    # @param iev [Nokogiri::XML::Element]
    # @param bibdb [Relaton::Db, NilClass]
    # @return [Nokogiri::XML::Element]
    def refs_iev2iec60050part(xml, parts, bibdb = nil)
      bibdb or return ""
      new_iev = ""
      parts.sort.each do |p|
        hit = get_iev_part(bibdb, p) or next
        new_iev += refs_iev2iec60050part1(xml, p, hit)
        update_iev_refs(xml, p, hit)
      end
      new_iev
    end

    def get_iev_part(bibdb, part)
      unless hit = bibdb.fetch("IEC 60050-#{part}", nil, keep_year: true)
        @err << "The IEV document 60050-#{part} that has been cited " \
                "does not exist"
      end
      hit
    end

    def update_iev_refs(xml, part, hit)
      xml.xpath(IEVPATH.gsub(/60050/, "60050-#{part}")).each do |x|
        x["citeas"] = @c.decode(x["citeas"])
          .sub(/:2011$/, ":#{hit.date[0].on(:year)}")
      end
    end

    def refs_iev2iec60050part1(xmldoc, part, hit)
      date = hit.date[0].on(:year)
      already_contains_ref(xmldoc, part, date) and return ""
      id = xmldoc.at("//bibitem[@id = 'IEC60050-#{part}']") ? "-1" : ""
      hit.to_xml.sub(/ id="[^"]+"/, %{ id="_#{UUIDTools::UUID.random_create}" anchor="IEC60050-#{part}#{id}"})
    end

    def already_contains_ref(xmldoc, part, date)
      xmldoc.at("//bibliography//bibitem[not(ancestor::bibitem)]/" \
                "docidentifier[@type = 'IEC']" \
                "[text() = 'IEC 60050-#{part}:#{date}']")
    end

    # @param xmldoc [Nokogiri::XML::Document]
    # @param bibdb [Relaton::Db, NilClass]
    # @return [Nokogiri::XML::Element], [String]
    def iev_cleanup(xmldoc, bibdb = nil)
      @c = HTMLEntities.new
      @err = []
      iev = xmldoc.at("//bibitem[docidentifier = 'IEC 60050:2011']") or
        return [nil, @err]
      parts = links_iev2iec60050part(xmldoc)
      [iev.replace(refs_iev2iec60050part(xmldoc, parts, bibdb)), @err]
    end
  end
end
