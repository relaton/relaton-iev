require "relaton"
require "relaton_iev/version"

module RelatonIev
  class Error < StandardError; end

  class << self
    # converts generic IEV citation to citation of IEC 60050-n
    # assumes IEV citations are of form
    # <eref type="inline" bibitemid="a" citeas="IEC 60050">
    # <locality type="clause"><referenceFrom>101-01-01</referenceFrom></locality></eref>
    #
    # @param xmldoc [Nokogiri::XML::Documet]
    # @return [Set<String>]
    def linksIev2iec60050part(xmldoc)
      parts = Set.new
      xmldoc.xpath("//eref[@citeas = 'IEC 60050:2011'] | "\
                   "//origin[@citeas = 'IEC 60050:2011']").each do |x|
        cl = x&.at(".//locality[@type = 'clause']/referenceFrom")&.text || next
        m = /^(\d+)/.match cl || next
        parts << m[0]
        x["citeas"] = x["citeas"].sub(/60050/, "60050-#{m[0]}")
        x["bibitemid"] = "IEC60050-#{m[0]}"
      end
      parts
    end

    # replace generic IEV reference with references to all extracted
    # IEV parts
    #
    # @param xmodoc [Nokogiri::XML::Document]
    # @param parts [Set<String>]
    # @param iev [Nokogiri::XML::Element]
    # @param bibdb [Relaton::Db, NilClass]
    # @return [Nokogiri::XML::Element]
    def refsIev2iec60050part(xmldoc, parts, iev, bibdb = nil)
      new_iev = ""
      parts.sort.each do |p|
        hit = bibdb&.fetch("IEC 60050-#{p}", nil, keep_year: true) || next
        date = hit.date[0].on(:year)
        new_iev += refsIev2iec60050part1(xmldoc, p, hit)
        xmldoc.xpath("//*[@citeas = 'IEC 60050-#{p}:2011']").each do |x|
          x["citeas"] = x["citeas"].sub(/:2011$/, ":#{date}")
        end
      end
      iev.replace(new_iev)
    end

    def refsIev2iec60050part1(xmldoc, part, hit)
      date = hit.date[0].on(:year)
      return "" if already_contains_ref(xmldoc, part, date)

      id = xmldoc.at("//bibitem[@id = 'IEC60050-#{part}']") ? "-1" : ""
      hit.to_xml.sub(/ id="[^"]+"/, %{ id="IEC60050-#{part}#{id}"})
    end

    def already_contains_ref(xmldoc, part, date)
      xmldoc.at("//bibliography//bibitem[not(ancestor::bibitem)]/"\
                "docidentifier[@type = 'IEC']"\
                "[text() = 'IEC 60050-#{part}:#{date}']")
    end

    # @param xmldoc [Nokogiri::XML::Document]
    # @param bibdb [Relaton::Db, NilClass]
    # @return [Nokogiri::XML::Element]
    def iev_cleanup(xmldoc, bibdb = nil)
      iev = xmldoc.at("//bibitem[docidentifier = 'IEC 60050:2011']") || return
      parts = linksIev2iec60050part(xmldoc)
      refsIev2iec60050part(xmldoc, parts, iev, bibdb)
    end
  end
end
