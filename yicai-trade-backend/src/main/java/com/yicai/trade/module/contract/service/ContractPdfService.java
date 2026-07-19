package com.yicai.trade.module.contract.service;

import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.*;
import com.lowagie.text.pdf.draw.LineSeparator;
import com.yicai.trade.module.contract.entity.Contract;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.awt.*;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Slf4j
@Service
public class ContractPdfService {

    @Value("${contract.pdf.storage-path:uploads/contracts}")
    private String storagePath;

    @Value("${contract.pdf.base-url:}")
    private String baseUrl;

    /**
     * 生成带盖章的合同PDF
     */
    public String generateSignedPdf(Contract contract) {
        try {
            Path dir = Paths.get(storagePath);
            Files.createDirectories(dir);

            String fileName = contract.getContractNo() + "_signed.pdf";
            Path filePath = dir.resolve(fileName);

            Document document = new Document(PageSize.A4, 60, 60, 60, 60);
            PdfWriter writer = PdfWriter.getInstance(document, new FileOutputStream(filePath.toFile()));
            document.open();

            // 使用内置字体（Helvetica支持ASCII字符，中文用simulated）
            BaseFont bfBold = BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
            BaseFont bfNormal = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);

            Font titleFont = new Font(bfBold, 18, Font.BOLD, new Color(0, 80, 120));
            Font headerFont = new Font(bfBold, 12, Font.BOLD, new Color(50, 50, 50));
            Font normalFont = new Font(bfNormal, 10, Font.NORMAL, Color.DARK_GRAY);
            Font smallFont = new Font(bfNormal, 8, Font.NORMAL, Color.GRAY);

            // 标题
            Paragraph title = new Paragraph("CONTRACT / Purchase Agreement", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(8);
            document.add(title);

            Paragraph contractNo = new Paragraph("Contract No: " + contract.getContractNo(), normalFont);
            contractNo.setAlignment(Element.ALIGN_CENTER);
            contractNo.setSpacingAfter(20);
            document.add(contractNo);

            // 分隔线
            addSeparator(document);

            // 合同标题
            Paragraph contractTitle = new Paragraph(contract.getContractTitle() != null ? contract.getContractTitle() : "Purchase Contract", headerFont);
            contractTitle.setSpacingBefore(10);
            contractTitle.setSpacingAfter(15);
            document.add(contractTitle);

            // 基本信息表格
            PdfPTable infoTable = new PdfPTable(2);
            infoTable.setWidthPercentage(100);
            infoTable.setSpacingAfter(15);
            addInfoRow(infoTable, "Buyer ID:", String.valueOf(contract.getBuyerId()), normalFont);
            addInfoRow(infoTable, "Supplier ID:", String.valueOf(contract.getSupplierId()), normalFont);
            addInfoRow(infoTable, "Total Amount:", contract.getTotalAmount() + " " + contract.getCurrency(), normalFont);
            if (contract.getDeliveryDate() != null) {
                addInfoRow(infoTable, "Delivery Date:", contract.getDeliveryDate().toString(), normalFont);
            }
            if (contract.getPaymentTerms() != null) {
                addInfoRow(infoTable, "Payment Terms:", contract.getPaymentTerms(), normalFont);
            }
            document.add(infoTable);

            // 合同内容
            if (contract.getContractContent() != null && !contract.getContractContent().isBlank()) {
                addSeparator(document);
                Paragraph contentHeader = new Paragraph("Contract Terms", headerFont);
                contentHeader.setSpacingBefore(10);
                contentHeader.setSpacingAfter(8);
                document.add(contentHeader);

                // 截取内容（避免超长）
                String content = contract.getContractContent();
                if (content.length() > 3000) content = content.substring(0, 3000) + "...";
                Paragraph contentPara = new Paragraph(content, normalFont);
                contentPara.setSpacingAfter(15);
                document.add(contentPara);
            }

            // 签署信息区域
            addSeparator(document);
            Paragraph signHeader = new Paragraph("SIGNATURES", headerFont);
            signHeader.setSpacingBefore(15);
            signHeader.setSpacingAfter(10);
            document.add(signHeader);

            PdfPTable signTable = new PdfPTable(2);
            signTable.setWidthPercentage(100);
            signTable.setSpacingAfter(10);

            // 买方签署
            PdfPCell buyerCell = createSignCell(
                    "BUYER",
                    contract.getBuyerSignature(),
                    contract.getBuyerSignedAt(),
                    contract.getBuyerSignIp(),
                    Boolean.TRUE.equals(contract.getBuyerSigned()),
                    headerFont, normalFont, smallFont
            );
            signTable.addCell(buyerCell);

            // 卖方签署
            PdfPCell supplierCell = createSignCell(
                    "SUPPLIER",
                    contract.getSupplierSignature(),
                    contract.getSupplierSignedAt(),
                    contract.getSupplierSignIp(),
                    Boolean.TRUE.equals(contract.getSupplierSigned()),
                    headerFont, normalFont, smallFont
            );
            signTable.addCell(supplierCell);

            document.add(signTable);

            // 如果双方都签了，画盖章
            if (Boolean.TRUE.equals(contract.getBuyerSigned()) && Boolean.TRUE.equals(contract.getSupplierSigned())) {
                drawSealStamp(writer, document);
            }

            // 页脚
            Paragraph footer = new Paragraph(
                    "This document was electronically generated on " +
                    LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) +
                    " | YiCai Global Trade Platform",
                    smallFont
            );
            footer.setAlignment(Element.ALIGN_CENTER);
            footer.setSpacingBefore(30);
            document.add(footer);

            document.close();

            String url = (baseUrl.isEmpty() ? "" : baseUrl) + "/uploads/contracts/" + fileName;
            log.info("Contract PDF generated: {}", filePath);
            return url;

        } catch (Exception e) {
            log.error("Failed to generate contract PDF: contractNo={}", contract.getContractNo(), e);
            return null;
        }
    }

    private void addSeparator(Document document) throws DocumentException {
        Paragraph line = new Paragraph();
        line.add(new Chunk(new LineSeparator(0.5f, 100, new Color(200, 200, 200), Element.ALIGN_CENTER, -2)));
        document.add(line);
    }

    private void addInfoRow(PdfPTable table, String label, String value, Font font) {
        PdfPCell labelCell = new PdfPCell(new Phrase(label, font));
        labelCell.setBorder(0);
        labelCell.setPaddingBottom(5);
        table.addCell(labelCell);

        PdfPCell valueCell = new PdfPCell(new Phrase(value != null ? value : "-", font));
        valueCell.setBorder(0);
        valueCell.setPaddingBottom(5);
        table.addCell(valueCell);
    }

    private PdfPCell createSignCell(String role, String signature, LocalDateTime signedAt,
                                     String signIp, boolean signed,
                                     Font headerFont, Font normalFont, Font smallFont) {
        PdfPCell cell = new PdfPCell();
        cell.setPadding(15);
        cell.setBorderColor(new Color(200, 200, 200));

        cell.addElement(new Paragraph(role, headerFont));

        if (signed) {
            Paragraph sigPara = new Paragraph("Signed by: " + (signature != null ? signature : "Confirmed"), normalFont);
            sigPara.setSpacingBefore(8);
            cell.addElement(sigPara);

            if (signedAt != null) {
                Paragraph timePara = new Paragraph("Time: " + signedAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")), smallFont);
                cell.addElement(timePara);
            }
            if (signIp != null) {
                Paragraph ipPara = new Paragraph("IP: " + signIp, smallFont);
                cell.addElement(ipPara);
            }

            // 签署状态标记
            Paragraph statusPara = new Paragraph("[CONFIRMED]", new Font(Font.HELVETICA, 10, Font.BOLD, new Color(0, 150, 0)));
            statusPara.setSpacingBefore(5);
            cell.addElement(statusPara);
        } else {
            Paragraph pending = new Paragraph("[PENDING]", new Font(Font.HELVETICA, 10, Font.NORMAL, Color.ORANGE));
            pending.setSpacingBefore(8);
            cell.addElement(pending);
        }

        return cell;
    }

    /**
     * 绘制电子印章效果（红色圆形章）
     */
    private void drawSealStamp(PdfWriter writer, Document document) {
        PdfContentByte cb = writer.getDirectContent();

        float pageWidth = document.getPageSize().getWidth();
        float centerX = pageWidth / 2;
        float centerY = 180; // 距底部

        // 红色圆圈
        cb.setColorStroke(new Color(200, 30, 30));
        cb.setLineWidth(2.5f);
        cb.circle(centerX, centerY, 45);
        cb.stroke();

        // 中间五角星
        cb.setColorFill(new Color(200, 30, 30));
        drawStar(cb, centerX, centerY, 15);
        cb.fill();

        // 上弧文字 "YiCai Trade"
        try {
            BaseFont bf = BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
            cb.beginText();
            cb.setFontAndSize(bf, 8);
            cb.setColorFill(new Color(200, 30, 30));
            // 弧形排列文字
            String text = "YICAI GLOBAL TRADE";
            float radius = 35;
            float startAngle = 200; // 从左上开始
            float anglePerChar = 160f / (text.length() - 1);
            for (int i = 0; i < text.length(); i++) {
                float angle = (float) Math.toRadians(startAngle - i * anglePerChar);
                float x = centerX + (float) Math.cos(angle) * radius;
                float y = centerY + (float) Math.sin(angle) * radius;
                cb.showTextAligned(Element.ALIGN_CENTER, String.valueOf(text.charAt(i)), x, y, 0);
            }
            cb.endText();

            // 底部文字
            cb.beginText();
            cb.setFontAndSize(bf, 7);
            cb.showTextAligned(Element.ALIGN_CENTER, "E-SEAL", centerX, centerY - 30, 0);
            cb.endText();
        } catch (Exception e) {
            log.warn("Failed to draw seal text", e);
        }
    }

    private void drawStar(PdfContentByte cb, float cx, float cy, float r) {
        float innerR = r * 0.4f;
        float[] xPoints = new float[10];
        float[] yPoints = new float[10];

        for (int i = 0; i < 10; i++) {
            float angle = (float) (Math.PI / 2 + i * Math.PI / 5);
            float radius = (i % 2 == 0) ? r : innerR;
            xPoints[i] = cx + (float) Math.cos(angle) * radius;
            yPoints[i] = cy + (float) Math.sin(angle) * radius;
        }

        cb.moveTo(xPoints[0], yPoints[0]);
        for (int i = 1; i < 10; i++) {
            cb.lineTo(xPoints[i], yPoints[i]);
        }
        cb.closePath();
    }
}
