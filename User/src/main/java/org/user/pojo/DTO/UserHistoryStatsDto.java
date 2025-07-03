package org.user.pojo.DTO;

import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;

public class UserHistoryStatsDto {
  private String id;
  @JsonProperty("totalScans")
  private Integer totalScans;
  @JsonProperty("barcodeScans")
  private Integer barcodeScans;
  @JsonProperty("receiptScans")
  private Integer receiptScans;
  @JsonProperty("averageHealthScore")
  private Double averageHealthScore;
  @JsonProperty("scansByDate")
  private Map<String, Integer> scansByDate;
  @JsonProperty("topCategories")
  private List<String> topCategories;

  public static class ScansByDateDto {
    private String date;
    private Integer count;

    @Override
    public String toString() {
      return "ScansByDateDto{" +
              "date='" + date + '\'' +
              ", count=" + count +
              '}';
    }
    public ScansByDateDto(String date, Integer count) {
      this.date = date;
      this.count = count;
    }
  }
  public static class TopCategoriesDto{
    private String category;
    private Integer count;

    @Override
    public String toString() {
      return "TopCategoriesDto{" +
              "category='" + category + '\'' +
              ", count=" + count +
              '}';
    }
    public TopCategoriesDto(String category, Integer count) {
      this.category = category;
      this.count = count;
    }
  }
  @Override
  public String toString() {
    return "UserHistoryStatsDto{" +
            "id='" + id + '\'' +
            ", totalScans=" + totalScans +
            ", barcodeScans=" + barcodeScans +
            ", receiptScans=" + receiptScans +
            ", averageHealthScore=" + averageHealthScore +
            ", scansByDate=" + scansByDate +
            ", topCategories=" + topCategories +
            '}';
  }
  

    /**
     * @return String return the id
     */
    public String getId() {
        return id;
    }

    /**
     * @param id the id to set
     */
    public void setId(String id) {
        this.id = id;
    }

    /**
     * @return Integer return the totalScans
     */
    public Integer getTotalScans() {
        return totalScans;
    }

    /**
     * @param totalScans the totalScans to set
     */
    public void setTotalScans(Integer totalScans) {
        this.totalScans = totalScans;
    }

    /**
     * @return Integer return the barcodeScans
     */
    public Integer getBarcodeScans() {
        return barcodeScans;
    }

    /**
     * @param barcodeScans the barcodeScans to set
     */
    public void setBarcodeScans(Integer barcodeScans) {
        this.barcodeScans = barcodeScans;
    }

    /**
     * @return Integer return the receiptScans
     */
    public Integer getReceiptScans() {
        return receiptScans;
    }

    /**
     * @param receiptScans the receiptScans to set
     */
    public void setReceiptScans(Integer receiptScans) {
        this.receiptScans = receiptScans;
    }

    /**
     * @return Double return the averageHealthScore
     */
    public Double getAverageHealthScore() {
        return averageHealthScore;
    }

    /**
     * @param averageHealthScore the averageHealthScore to set
     */
    public void setAverageHealthScore(Double averageHealthScore) {
        this.averageHealthScore = averageHealthScore;
    }

    /**
     * @return Map<String, Integer> return the scansByDate
     */
    public Map<String, Integer> getScansByDate() {
        return scansByDate;
    }

    /**
     * @param scansByDate the scansByDate to set
     */
    public void setScansByDate(Map<String, Integer> scansByDate) {
        this.scansByDate = scansByDate;
    }

    /**
     * @return List<String> return the topCategories
     */
    public List<String> getTopCategories() {
        return topCategories;
    }

    /**
     * @param topCategories the topCategories to set
     */
    public void setTopCategories(List<String> topCategories) {
        this.topCategories = topCategories;
    }
}
