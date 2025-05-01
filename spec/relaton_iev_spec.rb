RSpec.describe RelatonIev do
  it "has a version number" do
    expect(RelatonIev::VERSION).not_to be nil
  end

  it "manipulates a document" do
    bibdb = Relaton::Db.new nil, nil
    xmldoc = Nokogiri::XML <<~XML_DOC
      <standard-document>
          <eref citeas="IEC 60050:2011">
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
      xml, err = RelatonIev.iev_cleanup(xmldoc, bibdb)
      expect(err).to be_equivalent_to []
      expect(xml.first).to be_instance_of Nokogiri::XML::Element
      expect(strip_guid(xmldoc.root.to_xml))
        .to be_equivalent_to <<~OUTPUT
       <standard-document>
           <eref citeas="IEC&#xA0;60050-102:2007" bibitemid="IEC60050-102">
             <locality type="clause">
             <referenceFrom>102-01-01</referenceFrom>
             </locality>
           </eref>
         <bibitem id="_" anchor="IEC60050-102" type="standard">
         <fetched/>
         <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
         <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics -- General concepts and linear algebra</title>
         <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) - Part 102: Mathematics -- General concepts and linear algebra</title>
         <title type="title-main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV)</title>
         <title type="title-part" format="text/plain" language="fr" script="Latn">Partie 102: Math&#xE9;matiques -- Concepts g&#xE9;n&#xE9;raux et alg&#xE8;bre lin&#xE9;aire</title>
         <title type="main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV) - Partie 102: Math&#xE9;matiques -- Concepts g&#xE9;n&#xE9;raux et alg&#xE8;bre lin&#xE9;aire</title>
         <uri type="src">https://webstore.iec.ch/publication/160</uri>
         <uri type="obp">https://webstore.iec.ch/preview/info_iec60050-102{ed1.0}b.pdf</uri>
         <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
         <docidentifier type="URN">urn:iec:std:iec:60050-102:2007-08:::</docidentifier>
         <date type="published">
           <on>2007-08-27</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>International Electrotechnical Commission</name>
             <abbreviation>IEC</abbreviation>
             <uri>www.iec.ch</uri>
           </organization>
         </contributor>
         <edition>1</edition>
         <language>en</language>
         <language>fr</language>
         <script>Latn</script>
         <abstract format="text/html" language="en" script="Latn">This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions.<br/>It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
         <abstract format="text/html" language="fr" script="Latn">Cette partie de la CEI 60050 donne la terminologie math&#xE9;matique g&#xE9;n&#xE9;rale utilis&#xE9;e dans les domaines de l'&#xE9;lectricit&#xE9;, de l'&#xE9;lectronique et des t&#xE9;l&#xE9;communications, ainsi que les concepts fondamentaux d'alg&#xE8;bre lin&#xE9;aire. Elle maintient une distinction nette entre les concepts math&#xE9;matiques et les concepts physiques, m&#xEA;me si certains termes sont employ&#xE9;s dans les deux cas. Une autre partie traitera des fonctions.<br/>Elle a le statut de norme horizontale conform&#xE9;ment au Guide IEC 108.</abstract>
         <status>
           <stage>PUBLISHED</stage>
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
         <place>Geneva</place>
       </bibitem>
         <sections/>
       </standard-document>
        OUTPUT
    end
  end

  it "does not add a reference redundantly" do
    bibdb = Relaton::Db.new nil, nil
    VCR.use_cassette "iec" do
      xmldoc = Nokogiri::XML <<~XML_DOC
           <standard-document>
            <eref citeas="IEC 60050:2011">
              <locality type="clause">
              <referenceFrom>102-01-01</referenceFrom>
              </locality>
            </eref>
          <sections/>
          <bibliography>
          <references>
          <bibitem type="inline" bibitemid="a">
            <docidentifier>IEC 60050:2011</docidentifier>
          </bibitem>
          <bibitem id="IEC60050-102" type="standard">
           <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
           <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics - General concepts and linear algebra</title>
           <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) &#x2013; Part 102: Mathematics - General concepts and linear algebra</title>
           <uri type="src">https://webstore.iec.ch/publication/160</uri>
           <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
           <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
          </bibitem>
          </references>
          </bibliography>
        </standard-document>
      XML_DOC
      RelatonIev.iev_cleanup(xmldoc, bibdb)
      expect(xmldoc.to_xml.gsub(/ schema-version="[^"]+"/, ""))
        .to be_equivalent_to <<~OUTPUT
          <standard-document>
               <eref citeas="IEC&#xA0;60050-102:2007" bibitemid="IEC60050-102">
                 <locality type="clause">
                 <referenceFrom>102-01-01</referenceFrom>
                 </locality>
               </eref>
             <sections/>
             <bibliography>
             <references>

             <bibitem id="IEC60050-102" type="standard">
              <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
              <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics - General concepts and linear algebra</title>
              <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) &#x2013; Part 102: Mathematics - General concepts and linear algebra</title>
              <uri type="src">https://webstore.iec.ch/publication/160</uri>
              <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
              <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
             </bibitem>
             </references>
             </bibliography>
           </standard-document>
        OUTPUT
    end
  end

  it "does add a reference if not redundantly: different date" do
    bibdb = Relaton::Db.new nil, nil
    VCR.use_cassette "iec" do
      xmldoc = Nokogiri::XML <<~XML_DOC
          <standard-document>
            <eref citeas="IEC 60050:2011">
            <localityStack>
              <locality type="clause">
              <referenceFrom>102-01-01</referenceFrom>
              </locality>
            </localityStack>
            </eref>
          <sections/>
          <bibliography>
          <references>
          <bibitem type="inline" bibitemid="a">
            <docidentifier>IEC 60050:2011</docidentifier>
          </bibitem>
          <bibitem id="A" anchor="IEC60050-102" type="standard">
           <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
           <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics - General concepts and linear algebra</title>
           <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) &#x2013; Part 102: Mathematics - General concepts and linear algebra</title>
           <uri type="src">https://webstore.iec.ch/publication/160</uri>
           <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
           <docidentifier type="IEC" primary="true">IEC 60050-102:2008</docidentifier>
          </bibitem>
          </references>
          </bibliography>
        </standard-document>
      XML_DOC
      RelatonIev.iev_cleanup(xmldoc, bibdb)
      expect(strip_guid(xmldoc.root.to_xml))
        .to be_equivalent_to <<~OUTPUT
       <standard-document>
           <eref citeas="IEC&#xA0;60050-102:2007" bibitemid="IEC60050-102">
           <localityStack>
             <locality type="clause">
             <referenceFrom>102-01-01</referenceFrom>
             </locality>
           </localityStack>
           </eref>
         <sections/>
         <bibliography>
         <references>
         <bibitem id="_" anchor="IEC60050-102" type="standard">
         <fetched/>
         <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
         <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics -- General concepts and linear algebra</title>
         <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) - Part 102: Mathematics -- General concepts and linear algebra</title>
         <title type="title-main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV)</title>
         <title type="title-part" format="text/plain" language="fr" script="Latn">Partie 102: Math&#xE9;matiques -- Concepts g&#xE9;n&#xE9;raux et alg&#xE8;bre lin&#xE9;aire</title>
         <title type="main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV) - Partie 102: Math&#xE9;matiques -- Concepts g&#xE9;n&#xE9;raux et alg&#xE8;bre lin&#xE9;aire</title>
         <uri type="src">https://webstore.iec.ch/publication/160</uri>
         <uri type="obp">https://webstore.iec.ch/preview/info_iec60050-102{ed1.0}b.pdf</uri>
         <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
         <docidentifier type="URN">urn:iec:std:iec:60050-102:2007-08:::</docidentifier>
         <date type="published">
           <on>2007-08-27</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>International Electrotechnical Commission</name>
             <abbreviation>IEC</abbreviation>
             <uri>www.iec.ch</uri>
           </organization>
         </contributor>
         <edition>1</edition>
         <language>en</language>
         <language>fr</language>
         <script>Latn</script>
         <abstract format="text/html" language="en" script="Latn">This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions.<br/>It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
         <abstract format="text/html" language="fr" script="Latn">Cette partie de la CEI 60050 donne la terminologie math&#xE9;matique g&#xE9;n&#xE9;rale utilis&#xE9;e dans les domaines de l'&#xE9;lectricit&#xE9;, de l'&#xE9;lectronique et des t&#xE9;l&#xE9;communications, ainsi que les concepts fondamentaux d'alg&#xE8;bre lin&#xE9;aire. Elle maintient une distinction nette entre les concepts math&#xE9;matiques et les concepts physiques, m&#xEA;me si certains termes sont employ&#xE9;s dans les deux cas. Une autre partie traitera des fonctions.<br/>Elle a le statut de norme horizontale conform&#xE9;ment au Guide IEC 108.</abstract>
         <status>
           <stage>PUBLISHED</stage>
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
         <place>Geneva</place>
       </bibitem>
         <bibitem id="A" anchor="IEC60050-102" type="standard">
          <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
          <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics - General concepts and linear algebra</title>
          <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) &#x2013; Part 102: Mathematics - General concepts and linear algebra</title>
          <uri type="src">https://webstore.iec.ch/publication/160</uri>
          <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
          <docidentifier type="IEC" primary="true">IEC 60050-102:2008</docidentifier>
         </bibitem>
         </references>
         </bibliography>
       </standard-document>
        OUTPUT
    end
  end

  it "does add a reference if not redundantly: embedded ref" do
    bibdb = Relaton::Db.new nil, nil
    VCR.use_cassette "iec" do
      xmldoc = Nokogiri::XML <<~XML_DOC
           <standard-document>
            <eref citeas="IEC 60050:2011">
              <locality type="clause">
              <referenceFrom>102-01-01</referenceFrom>
              </locality>
            </eref>
          <sections/>
          <bibliography>
          <references>
          <bibitem type="inline" bibitemid="a">
            <docidentifier>IEC 60050:2011</docidentifier>
          </bibitem>
          <bibitem>
          <bibitem id="IEC60050-102" type="standard">
           <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
           <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics - General concepts and linear algebra</title>
           <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) &#x2013; Part 102: Mathematics - General concepts and linear algebra</title>
           <uri type="src">https://webstore.iec.ch/publication/160</uri>
           <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
           <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
          </bibitem>
          </bibitem>
          </references>
          </bibliography>
        </standard-document>
      XML_DOC
      RelatonIev.iev_cleanup(xmldoc, bibdb)
      expect(strip_guid(xmldoc.root.to_xml))
        .to be_equivalent_to <<~OUTPUT
            <standard-document>
           <eref citeas="IEC&#xA0;60050-102:2007" bibitemid="IEC60050-102">
             <locality type="clause">
             <referenceFrom>102-01-01</referenceFrom>
             </locality>
           </eref>
         <sections/>
         <bibliography>
         <references>
         <bibitem id="_" anchor="IEC60050-102-1" type="standard">
         <fetched/>
         <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
         <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics -- General concepts and linear algebra</title>
         <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) - Part 102: Mathematics -- General concepts and linear algebra</title>
         <title type="title-main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV)</title>
         <title type="title-part" format="text/plain" language="fr" script="Latn">Partie 102: Math&#xE9;matiques -- Concepts g&#xE9;n&#xE9;raux et alg&#xE8;bre lin&#xE9;aire</title>
         <title type="main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV) - Partie 102: Math&#xE9;matiques -- Concepts g&#xE9;n&#xE9;raux et alg&#xE8;bre lin&#xE9;aire</title>
         <uri type="src">https://webstore.iec.ch/publication/160</uri>
         <uri type="obp">https://webstore.iec.ch/preview/info_iec60050-102{ed1.0}b.pdf</uri>
         <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
         <docidentifier type="URN">urn:iec:std:iec:60050-102:2007-08:::</docidentifier>
         <date type="published">
           <on>2007-08-27</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>International Electrotechnical Commission</name>
             <abbreviation>IEC</abbreviation>
             <uri>www.iec.ch</uri>
           </organization>
         </contributor>
         <edition>1</edition>
         <language>en</language>
         <language>fr</language>
         <script>Latn</script>
         <abstract format="text/html" language="en" script="Latn">This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions.<br/>It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
         <abstract format="text/html" language="fr" script="Latn">Cette partie de la CEI 60050 donne la terminologie math&#xE9;matique g&#xE9;n&#xE9;rale utilis&#xE9;e dans les domaines de l'&#xE9;lectricit&#xE9;, de l'&#xE9;lectronique et des t&#xE9;l&#xE9;communications, ainsi que les concepts fondamentaux d'alg&#xE8;bre lin&#xE9;aire. Elle maintient une distinction nette entre les concepts math&#xE9;matiques et les concepts physiques, m&#xEA;me si certains termes sont employ&#xE9;s dans les deux cas. Une autre partie traitera des fonctions.<br/>Elle a le statut de norme horizontale conform&#xE9;ment au Guide IEC 108.</abstract>
         <status>
           <stage>PUBLISHED</stage>
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
         <place>Geneva</place>
       </bibitem>
         <bibitem>
         <bibitem id="IEC60050-102" type="standard">
          <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
          <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics - General concepts and linear algebra</title>
          <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) &#x2013; Part 102: Mathematics - General concepts and linear algebra</title>
          <uri type="src">https://webstore.iec.ch/publication/160</uri>
          <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
          <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
         </bibitem>
         </bibitem>
         </references>
         </bibliography>
       </standard-document>
        OUTPUT
    end
  end

  it "raises error if non-existent IEV document is cited" do
    bibdb = Relaton::Db.new nil, nil
    xmldoc = Nokogiri::XML <<~XML_DOC
      <standard-document>
          <eref citeas="IEC 60050:2011">
            <locality type="clause">
            <referenceFrom>02-01-01</referenceFrom>
            </locality>
          </eref>
        <bibitem type="inline" bibitemid="a">
          <docidentifier>IEC 60050:2011</docidentifier>
        </bibitem>
        <sections/>
      </standard-document>
    XML_DOC
    VCR.use_cassette "iev-02" do
      _xml, err = RelatonIev.iev_cleanup(xmldoc, bibdb)
      expect(err).to be_equivalent_to ["The IEV document 60050-02 that has been cited does not exist"]
    end
  end
end
