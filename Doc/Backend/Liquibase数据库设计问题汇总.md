# Liquibase数据库设计问题汇总

## 一、问题概述

在Grocery Guardian项目后端数据库设计与Liquibase迁移文件中，发现了多项可能导致数据库迁移失败、数据一致性风险和性能隐患的问题。现系统性梳理如下，供后端团队参考与修正。

---

## 二、详细问题列表

### 1. barcode相关字段命名不一致（最严重）
- 同一业务字段（商品条码）在不同表、不同changelog文件中命名不统一：
  - `barcode`、`bar_code`、`等混用
- 直接后果：
  - 外键约束无法建立，迁移失败
  - 唯一约束、索引等引用字段名不一致，迁移失败
  - 查询、数据同步复杂化，易出错
- 典型案例：
  - `product_preference.bar_code` 外键引用 `product(barcode)`，导致外键失效
 

### 2. 外键约束名重复
- 多个changelog文件中定义了同名外键（如`fk_product_preference_user`）
- 多次迁移或结构未清理时，Liquibase会报"Duplicate foreign key constraint name"
- 建议：外键名加上表前缀或唯一标识

### 3. 外键目标字段名与实际字段名不一致
- 外键引用字段名与目标表实际字段名不一致（如`bar_code` vs `barcode`）
- 直接导致外键无法建立，迁移失败

### 4. 唯一约束/索引引用字段名不一致
- 唯一约束、索引等如果引用了不存在的字段名，也会导致迁移失败
- 例如唯一约束写`user_id, bar_code`，但表结构里字段名写错

### 5. 外键约束缺失或被注释
- 有的表（如`scan_history`）的外键约束被注释，导致数据层面无法保证一致性
- 有的表（如`purchase_record`的`scan_id`）理论上应有外键，但实际未加

### 6. 数据类型不统一
- 业务相关字段（如糖分含量）在不同表中类型不一致（FLOAT/DOUBLE），可能导致数据精度或兼容性问题

### 7. 约束设计不合理
- 唯一约束设计不合理，可能导致业务无法扩展（如`product_preference`的复合唯一约束）
- 检查约束（CHECK）如果字段名写错，也会导致迁移失败

### 8. 索引设计不完善
- 有些高频查询字段（如barcode）未加索引，影响性能
- 复合索引、单字段索引命名不统一

---

## 三、建议与后续措施

1. **统一所有changelog文件的字段命名**，尤其是barcode相关，建议全部用`barcode`。
2. **检查所有外键、索引、唯一约束的引用字段名**，确保100%一致。
3. **为高频查询字段补充索引**，并统一索引命名规范。
4. **补充缺失的外键约束**，避免数据孤岛。
5. **统一数据类型**，保证业务字段精度一致。
6. **优化约束设计**，兼顾业务扩展性和数据完整性。
7. **定期代码审查和数据库迁移测试**，及时发现和修复问题。

---

## 四、关于"映射层"与数据库命名不统一的技术说明


### 1. Liquibase迁移的本质
- Liquibase执行changelog文件时，只认changelog里写的真实数据库字段名。
- 如果changelog文件本身字段名不统一（如有的表用bar_code，有的用barcode），外键、索引、唯一约束等引用时就会找不到目标字段，迁移直接报错。
- Liquibase不会"自动识别"或"自动映射"字段名，映射层对迁移无效。

### 2. 典型错误场景
- product表主键叫barcode，product_preference表外键写bar_code，changelog里直接写死，Liquibase迁移时会报"找不到字段"或"外键无法建立"。
- 代码层即使加了映射，数据库结构本身依然冲突，迁移失败。

### 3. 结论
- 映射层只能解决接口/代码与数据库的字段名不一致问题，**不能解决Liquibase迁移时changelog文件内部命名不统一导致的外键、索引、唯一约束冲突**。
- 要彻底解决迁移问题，**必须在所有changelog文件中统一字段命名**，保证所有外键、索引、唯一约束引用的字段名完全一致。

---

## 六、主要问题对应解决方案

### 1. barcode相关字段命名不一致
- **解决方案**：
  - 全局查找所有涉及商品条码的字段（如bar_code、product_barcode、request_barcode等），统一命名为barcode。
  - 修改所有changelog文件、表结构、外键、索引、唯一约束等引用，保持一致。
  - 代码层建议同步统一，减少维护成本。

### 2. 外键约束名重复
- **解决方案**：
  - 检查所有changelog文件，确保外键名唯一。
  - 建议外键名加上表前缀或唯一标识，如fk_product_preference_user_id。
  - 删除或合并重复定义的外键。

### 3. 外键目标字段名与实际字段名不一致
- **解决方案**：
  - 检查所有外键定义，确保baseColumnNames和referencedColumnNames与表结构字段完全一致。
  - 统一字段命名后，所有外键引用同步修正。

### 4. 唯一约束/索引引用字段名不一致
- **解决方案**：
  - 检查所有唯一约束、索引定义，确保引用字段名存在且一致。
  - 统一命名后，所有相关约束同步修正。

### 5. 外键约束缺失或被注释
- **解决方案**：
  - 补充所有应有的外键约束，确保数据一致性。
  - 如因微服务拆分暂时无法加外键，需在文档中注明并做好数据同步校验。

### 6. 数据类型不统一
- **解决方案**：
  - 统一业务相关字段的数据类型（如糖分含量全部用DOUBLE或DECIMAL）。
  - 修改changelog文件和表结构，保持类型一致。

### 7. 约束设计不合理
- **解决方案**：
  - 重新评估唯一约束、检查约束的业务合理性，必要时调整为更灵活的设计。
  - 检查约束字段名，确保存在且正确。

### 8. 索引设计不完善
- **解决方案**：
  - 为高频查询字段（如barcode、user_id、consumed_at等）补充单字段或联合索引。
  - 统一索引命名规范，便于维护。

### 9. 映射层误区澄清
- **解决方案**：
  - 明确映射层（如ORM注解）只能解决代码与数据库字段名不一致，不能解决Liquibase迁移时changelog文件内部命名不统一导致的迁移失败。
  - 必须在changelog文件中统一命名，保证所有引用一致。

---

## 七、具体问题位置与修改建议

### 1. barcode相关字段命名不一致
- **问题位置举例**：
  - `Backend/src/main/resources/db/moduleChangelog/product/microhard_product_preference_1.0.0.xml`：`<column name="bar_code" ...>`，外键`baseColumnNames="bar_code"`，引用`referencedColumnNames="barcode"`
 
- **修改建议**：
  - 将所有`bar_code`、`product_barcode`等字段统一改为`barcode`。
  - 同步修改所有外键、索引、唯一约束的字段名引用。
  
    ```

### 2. 外键约束名重复
- **问题位置举例**：
  - `Backend/src/main/resources/db/moduleChangelog/product/microhard_product_preference_1.0.0.xml`：`constraintName="fk_product_preference_user"`
  - `Backend/src/main/resources/db/moduleChangelog/user/microhard_user_preference_1.0.0.xml`：`constraintName="fk_product_preference_user"`
- **修改建议**：
  - 外键名加表前缀，确保唯一。
  - 示例：
    ```xml
    <!-- 修改前 -->
    constraintName="fk_product_preference_user"
    <!-- 修改后 -->
    constraintName="fk_product_preference_user_id"
    ```

### 3. 外键目标字段名与实际字段名不一致
- **问题位置举例**：
  - `Backend/src/main/resources/db/moduleChangelog/product/microhard_product_preference_1.0.0.xml`：`baseColumnNames="bar_code" referencedColumnNames="barcode"`
- **修改建议**：
  - baseColumnNames和referencedColumnNames都统一为`barcode`。

### 4. 唯一约束/索引引用字段名不一致
- **问题位置举例**：
  - `Backend/src/main/resources/db/moduleChangelog/product/microhard_product_preference_1.0.0.0.xml`：`<addUniqueConstraint columnNames="user_id, bar_code" ...>`
- **修改建议**：
  - 改为`columnNames="user_id, barcode"`。

### 5. 外键约束缺失或被注释
- **问题位置举例**：
  - `Backend/src/main/resources/db/moduleChangelog/userBehavior/microhard_scan_history_1.0.0.xml`：外键约束被注释：
    ```xml
    <!-- <addForeignKeyConstraint ... baseColumnNames="barcode" ...> -->
    ```
- **修改建议**：
  - 取消注释，补充外键约束，或在文档中注明原因。



---

**文档版本**: 1.0  
**最后更新**: 2025年1月  
**维护人员**: 后端开发团队 