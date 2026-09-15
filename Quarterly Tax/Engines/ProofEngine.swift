import UIKit

struct ProofEngine {
    static func generateAuditPackPDF(payments: [Payment], taxYear: Int, version: String) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let titleFont = UIFont.boldSystemFont(ofSize: 22)
        let headingFont = UIFont.boldSystemFont(ofSize: 14)
        let bodyFont = UIFont.systemFont(ofSize: 11)
        let captionFont = UIFont.italicSystemFont(ofSize: 9)
        let margin: CGFloat = 48
        let contentWidth = pageRect.width - margin * 2

        let sorted = payments.sorted { $0.paidAt < $1.paidAt }

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            func draw(_ text: String, font: UIFont, color: UIColor = .black, spacing: CGFloat = 6) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
                let size = (text as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs, context: nil)
                if y + size.height > pageRect.height - margin - 24 {
                    ctx.beginPage()
                    y = margin
                }
                (text as NSString).draw(in: CGRect(x: margin, y: y, width: contentWidth, height: size.height), withAttributes: attrs)
                y += size.height + spacing
            }

            draw("QuarterSafe Tax Proof Pack", font: titleFont, spacing: 4)
            draw("Tax year \(taxYear) · Generated \(Date.now.formatted(date: .abbreviated, time: .omitted))", font: bodyFont, color: .darkGray, spacing: 18)

            guard !sorted.isEmpty else {
                draw("No payments recorded yet.", font: bodyFont, spacing: 12)
                draw("Total recorded payments: $0", font: headingFont, spacing: 18)
                let emptyDisclaimer = "QuarterSafe provides estimates for planning only and is not tax advice. Verify with IRS Publication 505 / Form 1040-ES or a CPA. Tax tables version \(version). Always confirm deadlines on irs.gov."
                draw(emptyDisclaimer, font: captionFont, color: .darkGray, spacing: 0)
                return
            }

            for payment in sorted {
                let amount = Money.parse(payment.amountText) ?? 0
                draw("QuarterSafe payment · \(payment.quarterRaw) \(payment.taxYear)", font: headingFont, spacing: 4)
                draw("Amount: \(Money.text(amount, style: .exact))", font: bodyFont, spacing: 3)
                draw("Paid on: \(payment.paidAt.formatted(date: .abbreviated, time: .omitted))", font: bodyFont, spacing: 3)
                draw("Method: \(payment.method)", font: bodyFont, spacing: 3)
                if !payment.confirmationNumber.isEmpty {
                    draw("Confirmation #: \(payment.confirmationNumber)", font: bodyFont, spacing: 3)
                }
                if !payment.note.isEmpty {
                    draw("Note: \(payment.note)", font: bodyFont, spacing: 3)
                }
                if let photoData = payment.proofPhotoData,
                   let image = UIImage(data: photoData) {
                    let maxW: CGFloat = 240
                    let scale = min(maxW / image.size.width, 180 / image.size.height)
                    let imgSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    if y + imgSize.height > pageRect.height - margin - 24 {
                        ctx.beginPage()
                        y = margin
                    }
                    image.draw(in: CGRect(x: margin, y: y, width: imgSize.width, height: imgSize.height))
                    y += imgSize.height + 4
                    draw("Proof photo attached above", font: captionFont, color: .darkGray, spacing: 10)
                } else {
                    y += 10
                }
                draw(String(repeating: "—", count: 48), font: bodyFont, color: .lightGray, spacing: 10)
            }

            let total = sorted.reduce(Decimal(0)) { $0 + (Money.parse($1.amountText) ?? 0) }
            draw("Total recorded payments: \(Money.text(total, style: .exact))", font: headingFont, spacing: 18)

            let disclaimer = "QuarterSafe provides estimates for planning only and is not tax advice. Verify with IRS Publication 505 / Form 1040-ES or a CPA. Tax tables version \(version). Always confirm deadlines on irs.gov."
            draw(disclaimer, font: captionFont, color: .darkGray, spacing: 0)
        }
    }
}
