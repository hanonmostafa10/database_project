<%@ Page Title="My products" Language="C#" MasterPageFile="~/Partner.master" AutoEventWireup="true" CodeBehind="PartnerProducts.aspx.cs" Inherits="WebApplication1.PartnerProducts" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>My products</h1>
    <p class="subtitle">Add or edit products, hide them from customers, and set discounts.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <asp:Panel ID="noBusinessPanel" runat="server" CssClass="card" Visible="false">
        <asp:Label ID="noBusinessText" runat="server"></asp:Label>
        <p><a class="btn" href="PartnerHome.aspx">Go to my business</a></p>
    </asp:Panel>

    <asp:Panel ID="productsPanel" runat="server">

        <asp:Label ID="suspendedNote" runat="server" CssClass="msg msg-warning"></asp:Label>

        <%-- Add / edit form (Upsert_Product) --%>
        <asp:Panel ID="productForm" runat="server" CssClass="card" Visible="false">
            <h2><asp:Label ID="productFormTitle" runat="server"></asp:Label></h2>
            <div class="row">
                <div class="field">
                    <label>Name</label>
                    <asp:TextBox ID="pName" runat="server" MaxLength="100"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Category</label>
                    <asp:TextBox ID="pCategory" runat="server" MaxLength="50" placeholder="e.g. Main Dishes"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Price (EGP)</label>
                    <asp:TextBox ID="pPrice" runat="server" TextMode="Number" step="0.01" min="0.01"></asp:TextBox>
                </div>
            </div>
            <div class="field">
                <label>Description <span class="hint">(optional)</span></label>
                <asp:TextBox ID="pDescription" runat="server" MaxLength="255"></asp:TextBox>
            </div>
            <div class="field">
                <asp:CheckBox ID="pAvailable" runat="server" Text=" Available to customers" Checked="true" />
            </div>
            <div class="btn-row">
                <asp:Button ID="saveProductBtn" runat="server" Text="Save product" CssClass="btn" OnClick="saveProduct_Click" />
                <asp:Button ID="cancelProductBtn" runat="server" Text="Cancel" CssClass="btn btn-secondary" OnClick="cancelForms_Click" />
            </div>
        </asp:Panel>

        <%-- Discount form (Set_Product_Promotion) --%>
        <asp:Panel ID="discountForm" runat="server" CssClass="card" Visible="false">
            <h2><asp:Label ID="discountFormTitle" runat="server"></asp:Label></h2>
            <p class="muted"><asp:Label ID="discountHint" runat="server"></asp:Label></p>
            <div class="row">
                <div class="field">
                    <label>Discount (EGP off the price)</label>
                    <asp:TextBox ID="dAmount" runat="server" TextMode="Number" step="0.01" min="0"></asp:TextBox>
                </div>
            </div>
            <div class="btn-row">
                <asp:Button ID="saveDiscountBtn" runat="server" Text="Set discount" CssClass="btn" OnClick="saveDiscount_Click" />
                <asp:Button ID="removeDiscountBtn" runat="server" Text="Remove discount" CssClass="btn btn-secondary" OnClick="removeDiscount_Click" />
                <asp:Button ID="cancelDiscountBtn" runat="server" Text="Cancel" CssClass="btn btn-secondary" OnClick="cancelForms_Click" />
            </div>
        </asp:Panel>

        <div class="card">
            <div class="card-head">
                <h2>All my products</h2>
                <asp:Button ID="addBtn" runat="server" Text="+ Add a product" CssClass="btn" OnClick="add_Click" />
            </div>
            <asp:GridView ID="productsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
                DataKeyNames="product_id,product_name,description,category,price,discount_amount,is_available"
                OnRowCommand="productsGrid_RowCommand" OnRowDataBound="productsGrid_RowDataBound"
                EmptyDataText="You have no products yet. Click &quot;Add a product&quot; to add your first one.">
                <Columns>
                    <asp:BoundField DataField="product_name" HeaderText="Product" />
                    <asp:BoundField DataField="category" HeaderText="Category" />
                    <asp:BoundField DataField="price" HeaderText="Price" DataFormatString="{0:N2}" />
                    <asp:BoundField DataField="discount_amount" HeaderText="Discount" DataFormatString="{0:N2}" />
                    <asp:BoundField DataField="final_price" HeaderText="Customer pays" DataFormatString="{0:N2}" />
                    <asp:TemplateField HeaderText="Status">
                        <ItemTemplate>
                            <asp:Label ID="availability" runat="server"></asp:Label>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="">
                        <ItemTemplate>
                            <asp:Button ID="editBtn" runat="server" Text="Edit" CssClass="btn btn-sm btn-secondary"
                                CommandName="EditProduct" CommandArgument="<%# Container.DataItemIndex %>" />
                            <asp:Button ID="discountBtn" runat="server" Text="Discount" CssClass="btn btn-sm btn-secondary"
                                CommandName="Discount" CommandArgument="<%# Container.DataItemIndex %>" />
                            <asp:Button ID="toggleBtn" runat="server" CssClass="btn btn-sm"
                                CommandName="Toggle" CommandArgument="<%# Container.DataItemIndex %>" />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </asp:Panel>

</asp:Content>
