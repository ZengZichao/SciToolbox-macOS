import Foundation

// MARK: - SampleData（I2：内置离线示例数据）

/// 内置 2~3 条 `OfflineDetail`（真实公开数据精简），
/// 在"本地工具/示例与教学"小节可离线打开，明确标"示例"徽标。
enum SampleData {

    /// UniProt P68871（人类血红蛋白 α 链变体）精简离线快照。
    static let uniProtSample = OfflineDetail(
        headerTitle: "Hemoglobin subunit alpha",
        headerSubtitle: "Homo sapiens (Human)",
        headerMeta: ["UniProt: P68871", "Length: 142 aa", "Sample data"],
        sections: [
            OfflineDetail.Section(title: "Function", rows: [
                OfflineDetail.Row(key: "Function", value: "Involved in oxygen transport from the lung to the various peripheral tissues.", copyable: false),
            ]),
            OfflineDetail.Section(title: "Sequence", rows: [
                OfflineDetail.Row(key: "Length", value: "142 aa", copyable: false),
                OfflineDetail.Row(key: "Mass (Da)", value: "15,258", copyable: true),
                OfflineDetail.Row(key: "Sequence", value: "MVLSPADKTNVKAAWGKVGAHAGEYGAEALERMFLSFPTTKTYFPHFDLSHGSAQVKGHGKKVADALTNAVAHVDDMPNALSALSDLHAHKLRVDPVNFKLLSHCLLVTLAAHLPAEFTPAVHASLDKFLASVSTVLTSKYR", copyable: true),
            ]),
            OfflineDetail.Section(title: "Cross-references", rows: [
                OfflineDetail.Row(key: "PDB", value: "1A3N", copyable: true),
                OfflineDetail.Row(key: "GO", value: "GO:0005344 (oxygen transporter activity)", copyable: true),
            ]),
        ],
        freeTexts: [],
        actions: [],
        xlinks: [
            OfflineDetail.XLinkSnapshot(toolId: "pdb", query: "1A3N", label: "PDB: 1A3N"),
        ],
        sourceUrl: "https://www.uniprot.org/uniprot/P68871",
        capturedAt: Date()
    )

    /// PDB 4HHB（血红蛋白）精简离线快照。
    static let pdbSample = OfflineDetail(
        headerTitle: "Hemoglobin (Deoxy)",
        headerSubtitle: "Homo sapiens",
        headerMeta: ["PDB: 4HHB", "Resolution: 1.74 Å", "Sample data"],
        sections: [
            OfflineDetail.Section(title: "Structure", rows: [
                OfflineDetail.Row(key: "Method", value: "X-ray diffraction", copyable: false),
                OfflineDetail.Row(key: "Resolution", value: "1.74 Å", copyable: false),
                OfflineDetail.Row(key: "Chains", value: "A, B, C, D", copyable: false),
                OfflineDetail.Row(key: "Organism", value: "Homo sapiens", copyable: false),
            ]),
            OfflineDetail.Section(title: "Cross-references", rows: [
                OfflineDetail.Row(key: "UniProt", value: "P69905 (HBA), P68871 (HBB)", copyable: true),
            ]),
        ],
        freeTexts: [],
        actions: [],
        xlinks: [
            OfflineDetail.XLinkSnapshot(toolId: "uniprot", query: "P69905", label: "UniProt: P69905 (HBA)"),
            OfflineDetail.XLinkSnapshot(toolId: "uniprot", query: "P68871", label: "UniProt: P68871 (HBB)"),
        ],
        sourceUrl: "https://www.rcsb.org/structure/4HHB",
        capturedAt: Date()
    )

    /// PubMed 示例文献精简离线快照。
    static let pubMedSample = OfflineDetail(
        headerTitle: "The structure of human deoxyhaemoglobin at 1.74 Å resolution",
        headerSubtitle: "J Mol Biol, 1984",
        headerMeta: ["PMID: 6726807", "Sample data"],
        sections: [
            OfflineDetail.Section(title: "Citation", rows: [
                OfflineDetail.Row(key: "Authors", value: "Fermi G, Perutz MF, Shaanan B, Fourme R", copyable: false),
                OfflineDetail.Row(key: "Journal", value: "Journal of Molecular Biology", copyable: false),
                OfflineDetail.Row(key: "Year", value: "1984", copyable: false),
                OfflineDetail.Row(key: "Volume", value: "175", copyable: false),
                OfflineDetail.Row(key: "Pages", value: "159-174", copyable: false),
            ]),
        ],
        freeTexts: [
            OfflineDetail.FreeText(title: "Abstract", text: "The crystal structure of human deoxyhaemoglobin has been refined at 1.74 Å resolution...", copyable: false),
        ],
        actions: [
            OfflineDetail.Action(label: "Copy BibTeX", payload: "@article{Fermi1984, title={The structure of human deoxyhaemoglobin at 1.74 Å resolution}, author={Fermi, G and Perutz, M F and Shaanan, B and Fourme, R}, journal={J Mol Biol}, year={1984}, volume={175}, pages={159--174}}", kind: "export"),
        ],
        xlinks: [
            OfflineDetail.XLinkSnapshot(toolId: "pdb", query: "4HHB", label: "PDB: 4HHB"),
        ],
        sourceUrl: "https://pubmed.ncbi.nlm.nih.gov/6726807/",
        capturedAt: Date()
    )

    /// 全部示例数据（带来源标记）。
    static let allSamples: [(title: String, detail: OfflineDetail)] = [
        ("UniProt: Hemoglobin α", uniProtSample),
        ("PDB: 4HHB Hemoglobin", pdbSample),
        ("PubMed: 1984 Structure paper", pubMedSample),
    ]
}
