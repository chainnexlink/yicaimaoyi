package com.yicai.trade.module.certification.controller;

import com.yicai.trade.common.response.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@RequestMapping("/api/certification/upload")
@Tag(name = "认证文件上传", description = "认证材料文件上传与下载")
public class CertificationUploadController {

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    private static final Set<String> ALLOWED_TYPES = Set.of(
            "image/jpeg", "image/png", "image/gif", "image/webp",
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    );

    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

    @PostMapping
    @Operation(summary = "上传认证材料文件")
    public Result<Map<String, String>> upload(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            return Result.badRequest("文件不能为空");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            return Result.badRequest("文件大小不能超过10MB");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_TYPES.contains(contentType)) {
            return Result.badRequest("不支持的文件类型，仅支持 JPG/PNG/GIF/PDF/DOC/DOCX");
        }

        // 按日期分目录存储
        String dateDir = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        Path certDir = Paths.get(uploadDir, "certification", dateDir);
        Files.createDirectories(certDir);

        // 生成安全的文件名
        String originalName = file.getOriginalFilename();
        String ext = "";
        if (originalName != null && originalName.contains(".")) {
            ext = originalName.substring(originalName.lastIndexOf('.'));
        }
        String newFileName = UUID.randomUUID().toString().replace("-", "") + ext;

        Path targetPath = certDir.resolve(newFileName);
        Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

        // 返回访问URL
        String fileUrl = "/api/certification/upload/files/certification/" + dateDir + "/" + newFileName;
        Map<String, String> result = new HashMap<>();
        result.put("url", fileUrl);
        result.put("name", originalName);
        result.put("size", String.valueOf(file.getSize()));
        return Result.success(result);
    }

    @GetMapping("/files/**")
    @Operation(summary = "访问上传的文件")
    public ResponseEntity<Resource> getFile(jakarta.servlet.http.HttpServletRequest request) {
        // 提取 /api/certification/upload/files/ 之后的路径
        String fullPath = request.getRequestURI();
        String prefix = "/api/certification/upload/files/";
        int idx = fullPath.indexOf(prefix);
        if (idx < 0) {
            return ResponseEntity.notFound().build();
        }
        String filePath = fullPath.substring(idx + prefix.length());

        // 安全检查：防止路径遍历
        if (filePath.contains("..") || filePath.contains("\\")) {
            return ResponseEntity.badRequest().build();
        }

        try {
            Path file = Paths.get(uploadDir).resolve(filePath).normalize();
            // 确保文件在上传目录内
            if (!file.startsWith(Paths.get(uploadDir).normalize())) {
                return ResponseEntity.badRequest().build();
            }

            Resource resource = new UrlResource(file.toUri());
            if (resource.exists() && resource.isReadable()) {
                String contentType = Files.probeContentType(file);
                if (contentType == null) {
                    contentType = "application/octet-stream";
                }
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .header(HttpHeaders.CACHE_CONTROL, "public, max-age=86400")
                        .body(resource);
            }
        } catch (MalformedURLException e) {
            // ignore
        } catch (IOException e) {
            // ignore
        }
        return ResponseEntity.notFound().build();
    }
}
