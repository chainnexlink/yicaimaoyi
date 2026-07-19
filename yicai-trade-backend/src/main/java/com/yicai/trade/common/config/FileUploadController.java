package com.yicai.trade.common.config;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/files")
@Tag(name = "通用文件", description = "受鉴权的业务文件上传与读取")
@RequiredArgsConstructor
public class FileUploadController {

    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024;
    private static final Set<String> ALLOWED_CATEGORIES = Set.of("physical-contracts");
    private static final Map<String, String> ALLOWED_TYPES = Map.of(
            "application/pdf", ".pdf",
            "image/jpeg", ".jpg",
            "image/png", ".png",
            "application/msword", ".doc",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document", ".docx"
    );

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    private final ResourceAuthorizationService authorization;

    @PostMapping("/upload")
    @Operation(summary = "上传业务文件")
    public Result<Map<String, Object>> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam Long contractId,
            @RequestParam(defaultValue = "physical-contracts") String category) throws IOException {
        authorization.assertContractAccess(contractId);
        if (file.isEmpty()) {
            return Result.badRequest("文件不能为空");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            return Result.badRequest("文件大小不能超过10MB");
        }
        if (!ALLOWED_CATEGORIES.contains(category)) {
            return Result.badRequest("不支持的文件分类");
        }
        String extension = ALLOWED_TYPES.get(file.getContentType());
        if (extension == null) {
            return Result.badRequest("不支持的文件类型，仅支持 PDF/JPG/PNG/DOC/DOCX");
        }
        if (!hasExpectedSignature(file, extension)) {
            return Result.badRequest("文件内容与声明的类型不匹配");
        }

        String dateDir = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);
        Path uploadRoot = Paths.get(uploadDir).toAbsolutePath().normalize();
        Path targetDir = uploadRoot.resolve(category).resolve(contractId.toString()).resolve(dateDir).normalize();
        if (!targetDir.startsWith(uploadRoot)) {
            return Result.badRequest("非法文件路径");
        }
        Files.createDirectories(targetDir);

        String fileName = UUID.randomUUID().toString().replace("-", "") + extension;
        Path target = targetDir.resolve(fileName);
        try (InputStream input = file.getInputStream()) {
            Files.copy(input, target, StandardCopyOption.REPLACE_EXISTING);
        }

        return Result.success(Map.of(
                "url", "/api/files/" + category + "/" + contractId + "/" + dateDir + "/" + fileName,
                "name", file.getOriginalFilename() == null ? fileName : file.getOriginalFilename(),
                "size", file.getSize()
        ));
    }

    @GetMapping("/{category}/{contractId}/{date}/{fileName}")
    @Operation(summary = "读取业务文件")
    public ResponseEntity<Resource> getFile(
            @PathVariable String category,
            @PathVariable Long contractId,
            @PathVariable String date,
            @PathVariable String fileName) throws IOException {
        authorization.assertContractAccess(contractId);
        if (!ALLOWED_CATEGORIES.contains(category)
                || !date.matches("\\d{8}")
                || !fileName.matches("[a-fA-F0-9]{32}\\.(pdf|jpg|png|doc|docx)")) {
            return ResponseEntity.badRequest().build();
        }

        Path uploadRoot = Paths.get(uploadDir).toAbsolutePath().normalize();
        Path file = uploadRoot.resolve(category).resolve(contractId.toString()).resolve(date).resolve(fileName).normalize();
        if (!file.startsWith(uploadRoot) || !Files.isRegularFile(file) || !Files.isReadable(file)) {
            return ResponseEntity.notFound().build();
        }

        Resource resource = new UrlResource(file.toUri());
        String contentType = Files.probeContentType(file);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType == null ? "application/octet-stream" : contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + fileName + "\"")
                .header(HttpHeaders.CACHE_CONTROL, "private, max-age=3600")
                .body(resource);
    }

    private boolean hasExpectedSignature(MultipartFile file, String extension) throws IOException {
        byte[] header = new byte[8];
        int length;
        try (InputStream input = file.getInputStream()) {
            length = input.read(header);
        }
        if (length < 4) return false;

        return switch (extension) {
            case ".pdf" -> header[0] == '%' && header[1] == 'P' && header[2] == 'D' && header[3] == 'F';
            case ".jpg" -> unsigned(header[0]) == 0xFF && unsigned(header[1]) == 0xD8 && unsigned(header[2]) == 0xFF;
            case ".png" -> length >= 8
                    && unsigned(header[0]) == 0x89 && header[1] == 'P' && header[2] == 'N' && header[3] == 'G'
                    && unsigned(header[4]) == 0x0D && unsigned(header[5]) == 0x0A
                    && unsigned(header[6]) == 0x1A && unsigned(header[7]) == 0x0A;
            case ".doc" -> unsigned(header[0]) == 0xD0 && unsigned(header[1]) == 0xCF
                    && unsigned(header[2]) == 0x11 && unsigned(header[3]) == 0xE0;
            case ".docx" -> header[0] == 'P' && header[1] == 'K'
                    && unsigned(header[2]) == 0x03 && unsigned(header[3]) == 0x04;
            default -> false;
        };
    }

    private int unsigned(byte value) {
        return value & 0xFF;
    }
}
