package org.loyalty.pojo.response;

public class ContractInfoResponse {
    private String contractAddress;
    private String ownerAddress;
    private String network;
    
    public ContractInfoResponse() {}
    
    public ContractInfoResponse(String contractAddress, String ownerAddress, String network) {
        this.contractAddress = contractAddress;
        this.ownerAddress = ownerAddress;
        this.network = network;
    }
    
    public String getContractAddress() {
        return contractAddress;
    }
    
    public void setContractAddress(String contractAddress) {
        this.contractAddress = contractAddress;
    }
    
    public String getOwnerAddress() {
        return ownerAddress;
    }
    
    public void setOwnerAddress(String ownerAddress) {
        this.ownerAddress = ownerAddress;
    }
    
    public String getNetwork() {
        return network;
    }
    
    public void setNetwork(String network) {
        this.network = network;
    }
} 