pragma solidity >=0.4.22 <0.6.0;
contract xiong {
    struct Company {
        string name;
        uint credibility;
        bool valid;
        uint property;
    }
    //收据状态：有效、完成、逾期（未使用）
    enum Status{ Active, Accomplished, Overdue }
    struct Proposal {
        address owner;
        address apayer;
        string payer;       //付款方
        string payee;       //收款方
        uint amount;        //金额
        uint credibility;   //信誉度
        Status status;      //应收账款状态
    }
    string sbank="bank";
    address bank;
    mapping(address => Company) com;
    Proposal[] proposals;

    event Transaction(string from, string to, uint amount);     
    event Transfer(string from, string to, string next_from, uint amount);      
    event Financing(string from, uint amount, uint flag);     
    event Settlement(string from, string to, uint amount, uint property);      
    
    /// Create a new ballot with $(_numProposals) different proposals.
    constructor() public {
        bank = msg.sender;
        com[bank].credibility = 9;
    }
    //管理节点
    function initnode(address addr, string name , uint property, uint level)  public{
            if (msg.sender != bank) 
            return ; 
        if(com[addr].valid == false){
            com[addr] = Company(name, level, true,property);
            return ;
        }
        else{
            com[addr].property += property;
            com[addr].credibility = level;
            return ;
        }
    }
    //建立交易
   function transaction(address receiver, uint amount) public{
        if(receiver==msg.sender)
        return ;
        proposals.push(Proposal(receiver,msg.sender,com[msg.sender].name, com[receiver].name, amount, com[msg.sender].credibility, Status.Active));
        emit Transaction(com[msg.sender].name, com[receiver].name, amount);
    }
    
    //交易账单转让
    function transfer(address receiver, uint amount) public{
        if(receiver==msg.sender)
            return;
        
        uint i;
        uint tot=amount;
        
        //优先转让对方的收据
        for(i = 0; i < proposals.length; i++){
            if(proposals[i].owner==msg.sender&&proposals[i].status == Status.Active&&proposals[i].credibility>0){
                if(proposals[i].amount<=tot){
                    proposals[i].status=Status.Accomplished;
                    proposals.push(Proposal(receiver,proposals[i].apayer,proposals[i].payer, com[receiver].name, proposals[i].amount,proposals[i].credibility, Status.Active));
                    tot-=proposals[i].amount;
                }
                else{
                    proposals[i].status=Status.Accomplished;
                    proposals.push(Proposal(receiver,proposals[i].apayer,proposals[i].payer, com[receiver].name, tot,proposals[i].credibility, Status.Active));
                    proposals.push(Proposal(proposals[i].owner,proposals[i].apayer,proposals[i].payer, proposals[i].payee, proposals[i].amount-tot,proposals[i].credibility, Status.Active));
                    tot = 0;
                    break;
                }
            }
        }
        if(tot !=0)
            com[msg.sender].property=com[msg.sender].property-tot;
        emit Transfer(com[msg.sender].name, com[receiver].name, com[msg.sender].name, amount);
    }
    
    //融资，高信誉度公司可以任意融资，其他公司根据所持有高信誉度公司的收据来决定融资的额度
    function financing(uint amount) public{
        uint i;
        
        //高信誉度公司可以任意融资
        if(com[msg.sender].credibility >0){
           proposals.push(Proposal(bank,msg.sender,com[msg.sender].name, sbank, amount, com[msg.sender].credibility, Status.Active));
            com[msg.sender].property += amount;
            emit Financing(com[msg.sender].name, com[msg.sender].property, 1);
        }
        else{
            uint used = 0;
            uint sum = 0;
         
            //已经使用的融资额度
            for(i = 0; i < proposals.length; i++){
                if(proposals[i].owner==bank&&proposals[i].status == Status.Active&&proposals[i].credibility>0)
                    used += proposals[i].amount;
            }
            //计算剩余融资额度是否超过所需金额，如果不超过，则失败   
            for(i = 0; i < proposals.length; i++){
                if(proposals[i].owner==msg.sender&&proposals[i].status == Status.Active&&proposals[i].credibility>0){
                    sum+=proposals[i].amount;
                    if(used+amount>sum)
                    emit Financing(com[msg.sender].name, com[msg.sender].property, 0);    
                    return ;
                }
            }
            proposals.push(Proposal(bank,msg.sender,com[msg.sender].name, sbank, amount, com[msg.sender].credibility, Status.Active));
            com[msg.sender].property += amount;
            emit Financing(com[msg.sender].name, com[msg.sender].property, 1);
        }
    }
    //结账
    function settlement(address receiver) public{
        if(receiver==msg.sender)
            return;
        
        for(uint i = 0;  i < proposals.length; i++){
            if(proposals[i].status == Status.Active&&proposals[i].apayer==msg.sender){
                if(com[msg.sender].property >= proposals[i].amount){
                    com[msg.sender].property -= proposals[i].amount;
                    com[receiver].property += proposals[i].amount;
                     proposals[i].status = Status.Accomplished;
                    emit Settlement(com[msg.sender].name, com[receiver].name,  proposals[i].amount, com[msg.sender].property);
                }
                else
                    break;
            }
        }
    }
   
}
