package com.yicai.trade.common.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(name = "分页结果", description = "分页查询的统一返回格式")
public class PageResult<T> {
    
    @Schema(description = "数据列表")
    private List<T> content;
    
    @Schema(description = "总记录数", example = "100")
    private long totalElements;
    
    @Schema(description = "总页数", example = "10")
    private int totalPages;
    
    @Schema(description = "当前页码（从0开始）", example = "0")
    private int pageNumber;
    
    @Schema(description = "每页条数", example = "10")
    private int pageSize;
    
    public static <T> PageResult<T> of(List<T> content, long totalElements, int pageNumber, int pageSize) {
        int totalPages = pageSize > 0 ? (int) Math.ceil((double) totalElements / pageSize) : 0;
        return PageResult.<T>builder()
                .content(content)
                .totalElements(totalElements)
                .totalPages(totalPages)
                .pageNumber(pageNumber)
                .pageSize(pageSize)
                .build();
    }
}
