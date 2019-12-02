RSpec.describe RelatonIev do
  it "has a version number" do
    expect(RelatonIev::VERSION).not_to be nil
  end

  it "manipulates a document" do
    bibdb = Relaton::Db.new nil, nil
    xmldoc = Nokogiri::XML <<~XML_DOC
      <standard-document>
          <eref citeas="IEC 60050:2011">
            <locality type="clause">
            <referenceFrom>102-01-01</referenceFrom>
            </locality>
          </eref>
        <bibitem type="inline" bibitemid="a">
          <docidentifier>IEC 60050:2011</docidentifier>
        </bibitem>
        <sections/>
      </standard-document>
    XML_DOC
    VCR.use_cassette "iec" do
      xml = RelatonIev.iev_cleanup(xmldoc, bibdb)
      expect(xml.first).to be_instance_of Nokogiri::XML::Element
      expect(xmldoc.to_xml).to be_equivalent_to <<~OUTPUT
       <standard-document>
           <eref citeas="IEC 60050-102:2007" bibitemid="IEC60050-102">
             <locality type="clause">
             <referenceFrom>102-01-01</referenceFrom>
             </locality>
           </eref>
         <bibitem id="IEC60050-102" type="standard">
         <fetched>#{Date.today.to_s}</fetched>
         <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
         <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics - General concepts and linear algebra</title>
         <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) &#x2013; Part 102: Mathematics - General concepts and linear algebra</title>
         <uri type="src">https://webstore.iec.ch/publication/160</uri>
         <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
         <docidentifier type="IEC">IEC 60050-102:2007</docidentifier>
         <date type="published">
           <on>2007</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>International Electrotechnical Commission</name>
             <abbreviation>IEC</abbreviation>
             <uri>www.iec.ch</uri>
           </organization>
         </contributor>
         <edition>1.0</edition>
         <language>en</language>
         <script>Latn</script>
         <abstract format="text/plain" language="en" script="Latn">This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions. It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
         <status>
           <stage>60</stage>
           <substage>60</substage>
         </status>
         <copyright>
           <from>2007</from>
           <owner>
             <organization>
               <name>International Electrotechnical Commission</name>
               <abbreviation>IEC</abbreviation>
               <uri>www.iec.ch</uri>
             </organization>
           </owner>
         </copyright>
       </bibitem>
         <sections/>
       </standard-document>
      OUTPUT
    end
  end
end
