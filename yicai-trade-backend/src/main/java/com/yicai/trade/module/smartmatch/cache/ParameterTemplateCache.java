package com.yicai.trade.module.smartmatch.cache;

import com.yicai.trade.module.smartmatch.dto.ProductParameter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 参数模板缓存 - 为常见品类提供预定义参数模板，避免AI调用延迟
 */
@Slf4j
@Component
public class ParameterTemplateCache {

    // 品类参数模板缓存
    private final Map<String, List<ProductParameter>> costTemplates = new ConcurrentHashMap<>();
    private final Map<String, List<ProductParameter>> fobTemplates = new ConcurrentHashMap<>();
    
    // AI响应缓存 (productName hash -> parameters)
    private final Map<String, CachedResponse> aiResponseCache = new ConcurrentHashMap<>();
    
    // 缓存有效期 (30分钟)
    private static final long CACHE_TTL_MS = 30 * 60 * 1000;

    @PostConstruct
    public void init() {
        log.info("初始化参数模板缓存...");
        initCostTemplates();
        initFOBTemplates();
        log.info("参数模板缓存初始化完成, 成本模板: {}个, FOB模板: {}个", 
                costTemplates.size(), fobTemplates.size());
    }

    /**
     * 获取成本参数模板
     */
    public List<ProductParameter> getCostTemplate(String categoryCode) {
        return costTemplates.get(categoryCode);
    }

    /**
     * 获取FOB参数模板
     */
    public List<ProductParameter> getFOBTemplate(String categoryCode) {
        return fobTemplates.get(categoryCode);
    }

    /**
     * 缓存AI响应
     */
    public void cacheAIResponse(String key, List<ProductParameter> parameters) {
        aiResponseCache.put(key, new CachedResponse(parameters, System.currentTimeMillis()));
        // 清理过期缓存
        cleanExpiredCache();
    }

    /**
     * 获取缓存的AI响应
     */
    public List<ProductParameter> getCachedAIResponse(String key) {
        CachedResponse cached = aiResponseCache.get(key);
        if (cached != null && !cached.isExpired()) {
            return cached.parameters;
        }
        return null;
    }

    /**
     * 生成缓存key
     */
    public String generateCacheKey(String productName, String categoryCode, String stage) {
        return String.format("%s_%s_%s", productName.toLowerCase().trim(), categoryCode, stage);
    }

    private void cleanExpiredCache() {
        aiResponseCache.entrySet().removeIf(entry -> entry.getValue().isExpired());
    }

    private void initCostTemplates() {
        // 通用产品模板 (适用于大多数产品)
        costTemplates.put("GENERAL", createGeneralCostTemplate());
        
        // 电子产品
        costTemplates.put("ELECTRONICS", createElectronicsCostTemplate());
        
        // 家居用品
        costTemplates.put("HOME_GOODS", createHomeGoodsCostTemplate());
        
        // 服装纺织
        costTemplates.put("TEXTILE", createTextileCostTemplate());
        
        // 包装材料
        costTemplates.put("PACKAGING", createPackagingCostTemplate());
        
        // 五金工具
        costTemplates.put("HARDWARE", createHardwareCostTemplate());
        
        // 塑料制品
        costTemplates.put("PLASTIC", createPlasticCostTemplate());
        
        // 金属制品
        costTemplates.put("METAL", createMetalCostTemplate());
    }

    private void initFOBTemplates() {
        // 通用FOB模板
        List<ProductParameter> generalFOB = Arrays.asList(
            ProductParameter.builder()
                .parameterName("供应商所在地")
                .parameterCode("origin_city")
                .parameterType("select")
                .options(Arrays.asList("深圳", "广州", "东莞", "义乌", "宁波", "上海", "苏州", "青岛", "天津"))
                .required(true)
                .description("供应商/发货地城市")
                .build(),
            ProductParameter.builder()
                .parameterName("起运港")
                .parameterCode("departure_port")
                .parameterType("select")
                .options(Arrays.asList("深圳港", "广州港", "宁波港", "上海港", "青岛港", "天津港"))
                .required(true)
                .description("货物起运港口")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("purchase_quantity")
                .parameterType("select")
                .options(Arrays.asList("1000-5000件", "5000-10000件", "10000-50000件", "50000件以上"))
                .required(true)
                .description("本次采购数量范围")
                .build(),
            ProductParameter.builder()
                .parameterName("包装方式")
                .parameterCode("packing_method")
                .parameterType("select")
                .options(Arrays.asList("纸箱包装", "木箱包装", "托盘包装", "散装"))
                .required(true)
                .description("出口包装方式")
                .build(),
            ProductParameter.builder()
                .parameterName("运输方式")
                .parameterCode("transport_mode")
                .parameterType("select")
                .options(Arrays.asList("海运整柜", "海运拼箱", "空运", "快递"))
                .required(true)
                .description("国际运输方式")
                .build()
        );
        
        fobTemplates.put("GENERAL", generalFOB);
        fobTemplates.put("ELECTRONICS", generalFOB);
        fobTemplates.put("HOME_GOODS", generalFOB);
        fobTemplates.put("TEXTILE", generalFOB);
        fobTemplates.put("PACKAGING", generalFOB);
        fobTemplates.put("HARDWARE", generalFOB);
        fobTemplates.put("PLASTIC", generalFOB);
        fobTemplates.put("METAL", generalFOB);
    }

    private List<ProductParameter> createGeneralCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("主要材质")
                .parameterCode("main_material")
                .parameterType("select")
                .options(Arrays.asList("塑料", "金属", "木材", "玻璃", "纸/纸板", "布料/纺织", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品主要材质")
                .build(),
            ProductParameter.builder()
                .parameterName("产品尺寸")
                .parameterCode("product_size")
                .parameterType("select")
                .options(Arrays.asList("小型(≤10cm)", "中型(10-30cm)", "大型(30-100cm)", "超大型(>100cm)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品最大边长尺寸")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("100-500", "500-1000", "1000-5000", "5000-10000", "10000以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("工艺复杂度")
                .parameterCode("craft_complexity")
                .parameterType("select")
                .options(Arrays.asList("简单(单一工艺)", "中等(2-3种工艺)", "复杂(多种工艺组合)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("生产工艺复杂程度")
                .build(),
            ProductParameter.builder()
                .parameterName("定制需求")
                .parameterCode("customization")
                .parameterType("select")
                .options(Arrays.asList("无定制(标准品)", "轻度定制(Logo/颜色)", "中度定制(尺寸/功能)", "深度定制(全新开发)"))
                .required(true)
                .description("产品定制化程度")
                .build(),
            ProductParameter.builder()
                .parameterName("质量等级")
                .parameterCode("quality_level")
                .parameterType("select")
                .options(Arrays.asList("经济型", "标准型", "优质型", "高端型"))
                .required(true)
                .description("产品质量定位")
                .build()
        );
    }

    private List<ProductParameter> createElectronicsCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("产品类型")
                .parameterCode("product_type")
                .parameterType("select")
                .options(Arrays.asList("消费电子", "工业电子", "通讯设备", "电源/充电器", "配件/线材", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("电子产品细分类型")
                .build(),
            ProductParameter.builder()
                .parameterName("主要材质")
                .parameterCode("main_material")
                .parameterType("select")
                .options(Arrays.asList("ABS塑料", "PC塑料", "金属外壳", "硅胶", "混合材质", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("外壳/主体材质")
                .build(),
            ProductParameter.builder()
                .parameterName("电路板复杂度")
                .parameterCode("pcb_complexity")
                .parameterType("select")
                .options(Arrays.asList("简单(单层PCB)", "中等(双层PCB)", "复杂(多层PCB)", "无电路板", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("电路板层数和复杂度")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("500-1000", "1000-5000", "5000-10000", "10000-50000", "50000以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("认证要求")
                .parameterCode("certification")
                .parameterType("select")
                .options(Arrays.asList("无特殊要求", "CE认证", "FCC认证", "多项认证", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品认证要求")
                .build(),
            ProductParameter.builder()
                .parameterName("定制需求")
                .parameterCode("customization")
                .parameterType("select")
                .options(Arrays.asList("无定制(标准品)", "外观定制", "功能定制", "全新开模"))
                .required(true)
                .description("产品定制化程度")
                .build()
        );
    }

    private List<ProductParameter> createHomeGoodsCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("产品类型")
                .parameterCode("product_type")
                .parameterType("select")
                .options(Arrays.asList("厨房用品", "卫浴用品", "收纳整理", "家居装饰", "清洁工具", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("家居用品细分类型")
                .build(),
            ProductParameter.builder()
                .parameterName("主要材质")
                .parameterCode("main_material")
                .parameterType("select")
                .options(Arrays.asList("不锈钢", "塑料PP/PE", "竹木", "玻璃", "陶瓷", "布艺", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品主要材质")
                .build(),
            ProductParameter.builder()
                .parameterName("产品尺寸")
                .parameterCode("product_size")
                .parameterType("select")
                .options(Arrays.asList("小型(≤15cm)", "中型(15-40cm)", "大型(40-80cm)", "超大型(>80cm)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品尺寸范围")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("500-2000", "2000-5000", "5000-20000", "20000以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("表面处理")
                .parameterCode("surface_treatment")
                .parameterType("select")
                .options(Arrays.asList("无特殊处理", "喷漆/烤漆", "电镀", "印刷/贴纸", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("表面处理工艺")
                .build(),
            ProductParameter.builder()
                .parameterName("定制需求")
                .parameterCode("customization")
                .parameterType("select")
                .options(Arrays.asList("无定制(标准品)", "Logo定制", "颜色/尺寸定制", "全新开发"))
                .required(true)
                .description("产品定制化程度")
                .build()
        );
    }

    private List<ProductParameter> createTextileCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("产品类型")
                .parameterCode("product_type")
                .parameterType("select")
                .options(Arrays.asList("服装", "家纺", "面料", "袋包", "配饰", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("纺织品细分类型")
                .build(),
            ProductParameter.builder()
                .parameterName("主要面料")
                .parameterCode("main_fabric")
                .parameterType("select")
                .options(Arrays.asList("棉", "涤纶", "尼龙", "混纺", "真丝", "麻", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("主要面料成分")
                .build(),
            ProductParameter.builder()
                .parameterName("克重/厚度")
                .parameterCode("fabric_weight")
                .parameterType("select")
                .options(Arrays.asList("轻薄(<150g/m²)", "中等(150-300g/m²)", "厚实(>300g/m²)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("面料克重")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("500-2000件", "2000-10000件", "10000-50000件", "50000件以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("印染工艺")
                .parameterCode("dyeing_process")
                .parameterType("select")
                .options(Arrays.asList("素色/染色", "印花", "刺绣", "提花", "无需", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("印染或装饰工艺")
                .build(),
            ProductParameter.builder()
                .parameterName("定制需求")
                .parameterCode("customization")
                .parameterType("select")
                .options(Arrays.asList("无定制(标准品)", "颜色定制", "尺码/款式定制", "全新设计"))
                .required(true)
                .description("产品定制化程度")
                .build()
        );
    }

    private List<ProductParameter> createPackagingCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("包装类型")
                .parameterCode("packaging_type")
                .parameterType("select")
                .options(Arrays.asList("纸箱", "纸盒", "塑料袋", "塑料盒", "金属罐", "玻璃瓶", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("包装材料类型")
                .build(),
            ProductParameter.builder()
                .parameterName("材质等级")
                .parameterCode("material_grade")
                .parameterType("select")
                .options(Arrays.asList("普通", "加厚", "特种(防水/防静电)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("材质等级和特性")
                .build(),
            ProductParameter.builder()
                .parameterName("尺寸规格")
                .parameterCode("size_spec")
                .parameterType("select")
                .options(Arrays.asList("小型(≤20cm)", "中型(20-40cm)", "大型(40-60cm)", "特大型(>60cm)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("包装尺寸")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("1000-5000", "5000-20000", "20000-100000", "100000以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("印刷需求")
                .parameterCode("printing")
                .parameterType("select")
                .options(Arrays.asList("无印刷", "单色印刷", "多色印刷", "全彩印刷"))
                .required(true)
                .description("印刷工艺需求")
                .build(),
            ProductParameter.builder()
                .parameterName("定制需求")
                .parameterCode("customization")
                .parameterType("select")
                .options(Arrays.asList("标准尺寸", "定制尺寸", "定制设计"))
                .required(true)
                .description("包装定制化程度")
                .build()
        );
    }

    private List<ProductParameter> createHardwareCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("产品类型")
                .parameterCode("product_type")
                .parameterType("select")
                .options(Arrays.asList("手动工具", "电动工具", "紧固件", "五金配件", "门窗五金", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("五金产品细分类型")
                .build(),
            ProductParameter.builder()
                .parameterName("主要材质")
                .parameterCode("main_material")
                .parameterType("select")
                .options(Arrays.asList("碳钢", "不锈钢", "合金钢", "铝合金", "铜/黄铜", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品主要材质")
                .build(),
            ProductParameter.builder()
                .parameterName("表面处理")
                .parameterCode("surface_treatment")
                .parameterType("select")
                .options(Arrays.asList("镀锌", "镀铬", "镀镍", "喷塑", "发黑", "无处理", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("表面处理工艺")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("500-2000", "2000-10000", "10000-50000", "50000以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("精度要求")
                .parameterCode("precision")
                .parameterType("select")
                .options(Arrays.asList("普通精度", "中等精度", "高精度", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("加工精度要求")
                .build(),
            ProductParameter.builder()
                .parameterName("定制需求")
                .parameterCode("customization")
                .parameterType("select")
                .options(Arrays.asList("标准品", "规格定制", "全新开发"))
                .required(true)
                .description("产品定制化程度")
                .build()
        );
    }

    private List<ProductParameter> createPlasticCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("塑料类型")
                .parameterCode("plastic_type")
                .parameterType("select")
                .options(Arrays.asList("PP", "PE", "ABS", "PC", "PVC", "PET", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("塑料材质类型")
                .build(),
            ProductParameter.builder()
                .parameterName("成型工艺")
                .parameterCode("molding_process")
                .parameterType("select")
                .options(Arrays.asList("注塑", "吹塑", "挤出", "吸塑", "压塑", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("塑料成型工艺")
                .build(),
            ProductParameter.builder()
                .parameterName("产品尺寸")
                .parameterCode("product_size")
                .parameterType("select")
                .options(Arrays.asList("小型(≤10cm)", "中型(10-30cm)", "大型(30-60cm)", "超大型(>60cm)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品尺寸范围")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("1000-5000", "5000-20000", "20000-100000", "100000以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("颜色要求")
                .parameterCode("color")
                .parameterType("select")
                .options(Arrays.asList("透明", "单色", "多色", "定制色"))
                .required(true)
                .description("产品颜色要求")
                .build(),
            ProductParameter.builder()
                .parameterName("模具情况")
                .parameterCode("mold_status")
                .parameterType("select")
                .options(Arrays.asList("有现成模具", "需要开新模", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("是否需要新开模具")
                .build()
        );
    }

    private List<ProductParameter> createMetalCostTemplate() {
        return Arrays.asList(
            ProductParameter.builder()
                .parameterName("金属类型")
                .parameterCode("metal_type")
                .parameterType("select")
                .options(Arrays.asList("碳钢", "不锈钢", "铝/铝合金", "铜/黄铜", "锌合金", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("金属材质类型")
                .build(),
            ProductParameter.builder()
                .parameterName("加工工艺")
                .parameterCode("processing")
                .parameterType("select")
                .options(Arrays.asList("冲压", "铸造", "锻造", "机加工", "钣金", "焊接", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("金属加工工艺")
                .build(),
            ProductParameter.builder()
                .parameterName("产品尺寸")
                .parameterCode("product_size")
                .parameterType("select")
                .options(Arrays.asList("小型(≤10cm)", "中型(10-30cm)", "大型(30-60cm)", "超大型(>60cm)", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("产品尺寸范围")
                .build(),
            ProductParameter.builder()
                .parameterName("采购数量")
                .parameterCode("quantity")
                .parameterType("select")
                .options(Arrays.asList("500-2000", "2000-10000", "10000-50000", "50000以上"))
                .required(true)
                .description("预计采购数量")
                .build(),
            ProductParameter.builder()
                .parameterName("表面处理")
                .parameterCode("surface_treatment")
                .parameterType("select")
                .options(Arrays.asList("无处理", "电镀", "喷涂", "阳极氧化", "抛光", "不清楚,由AI按行业常规预估"))
                .allowAIEstimate(true)
                .aiEstimateOption("不清楚,由AI按行业常规预估")
                .required(true)
                .description("表面处理工艺")
                .build(),
            ProductParameter.builder()
                .parameterName("定制需求")
                .parameterCode("customization")
                .parameterType("select")
                .options(Arrays.asList("标准品", "规格定制", "全新开发"))
                .required(true)
                .description("产品定制化程度")
                .build()
        );
    }

    // 缓存响应包装类
    private static class CachedResponse {
        final List<ProductParameter> parameters;
        final long timestamp;

        CachedResponse(List<ProductParameter> parameters, long timestamp) {
            this.parameters = parameters;
            this.timestamp = timestamp;
        }

        boolean isExpired() {
            return System.currentTimeMillis() - timestamp > CACHE_TTL_MS;
        }
    }
}
