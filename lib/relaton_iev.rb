require "relaton"
require "relaton_iev/version"

module RelatonIev
  class Error < StandardError; end

  class << self
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
      xmldoc.xpath("//*[@citeas = 'IEC 60050:2011']").each do |x|
        m = x&.at(".//locality[@type = 'clause']/referenceFrom")&.text
          &.sub(/^(\d+).*$/, "\\1") or next

        parts << m
        x["citeas"] = x["citeas"].sub(/60050/, "60050-#{m}")
        x["bibitemid"] = "IEC60050-#{m}"
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
    def refs_iev2iec60050part(xmldoc, parts, bibdb = nil)
      new_iev = ""
      parts.sort.each do |p|
        hit = bibdb&.fetch("IEC 60050-#{p}", nil, keep_year: true) or next
        new_iev += refs_iev2iec60050part1(xmldoc, p, hit)
        xmldoc.xpath("//*[@citeas = 'IEC 60050-#{p}:2011']").each do |x|
          x["citeas"] = x["citeas"].sub(/:2011$/, ":#{hit.date[0].on(:year)}")
        end
      end
      new_iev
    end

    def refs_iev2iec60050part1(xmldoc, part, hit)
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
      parts = links_iev2iec60050part(xmldoc)
      iev.replace(refs_iev2iec60050part(xmldoc, parts, bibdb))
    end
  end
end
