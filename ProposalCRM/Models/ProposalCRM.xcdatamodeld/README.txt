This is a placeholder for the Core Data model.

In Xcode, you'll need to:
1. Create a Data Model file named ProposalCRM.xcdatamodeld
2. Add the following entities with their attributes and relationships:

- Customer (id:UUID, name:String, email:String, phone:String, address:String)
- Product (id:UUID, code:String, name:String, description:String, category:String, listPrice:Double, partnerPrice:Double)
- Proposal (id:UUID, number:String, creationDate:Date, status:String, totalAmount:Double, notes:String)
- ProposalItem (id:UUID, quantity:Double, unitPrice:Double, discount:Double, amount:Double)
- Engineering (id:UUID, description:String, days:Double, rate:Double, amount:Double)
- Expense (id:UUID, description:String, amount:Double)
- CustomTax (id:UUID, name:String, rate:Double, amount:Double)

Relationships:
- Customer to Proposals (one-to-many)
- Proposal to Customer (many-to-one)
- Proposal to ProposalItems (one-to-many)
- Proposal to Engineering (one-to-many)
- Proposal to Expenses (one-to-many)
- Proposal to CustomTaxes (one-to-many)
- ProposalItem to Product (many-to-one)
- ProposalItem to Proposal (many-to-one)
