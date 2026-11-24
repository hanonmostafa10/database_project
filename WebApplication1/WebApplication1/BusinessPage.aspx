<%@ Page Title="Business" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="BusinessPage.aspx.cs" Inherits="WebApplication1.BusinessPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <p><a href="CustomerBrowse.aspx">&larr; Back to browsing</a></p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <asp:Panel ID="businessPanel" runat="server">
        <%-- 3.6 a: details, open now, rating --%>
        <div class="card">
            <div class="card-head">
                <div>
                    <h1><asp:Label ID="bizName" runat="server"></asp:Label>
                        <asp:Label ID="openBadge" runat="server" CssClass="status"></asp:Label></h1>
                    <asp:Label ID="bizDescription" runat="server" CssClass="muted"></asp:Label>
                </div>
                <asp:Button ID="favBusinessBtn" runat="server" CssClass="btn btn-secondary" OnClick="favBusiness_Click" />
            </div>
            <table class="details">
                <tr><th>Rating</th><td><asp:Label ID="bizRating" runat="server"></asp:Label></td></tr>
                <tr><th>Zone</th><td><asp:Label ID="bizZone" runat="server"></asp:Label></td></tr>
                <tr><th>Opening hours</th><td><asp:Label ID="bizHours" runat="server"></asp:Label></td></tr>
                <tr><th>Delivery time</th><td><asp:Label ID="bizDelivery" runat="server"></asp:Label></td></tr>
                <tr><th>Website</th><td><asp:Label ID="bizWebsite" runat="server"></asp:Label></td></tr>
            </table>
            <asp:Label ID="bizNote" runat="server" CssClass="msg msg-warning"></asp:Label>
        </div>

        <%-- 3.5 d: add products with a quantity and an optional note; 3.6 b: favorite products --%>
        <div class="card">
            <div class="card-head">
                <h2>Products</h2>
                <asp:Label ID="cartLine" runat="server" CssClass="muted"></asp:Label>
            </div>
            <asp:GridView ID="productsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
                DataKeyNames="product_id,product_name" OnRowCommand="productsGrid_RowCommand" OnRowDataBound="productsGrid_RowDataBound"
                EmptyDataText="This business has no products available right now.">
                <Columns>
                    <asp:TemplateField HeaderText="Product">
                        <ItemTemplate>
                            <b><%# HttpUtility.HtmlEncode((string)Eval("product_name")) %></b><br />
                            <span class="muted"><%# HttpUtility.HtmlEncode(Eval("description") as string ?? "") %></span>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="category" HeaderText="Category" />
                    <asp:TemplateField HeaderText="Price (EGP)">
                        <ItemTemplate><asp:Label ID="price" runat="server"></asp:Label></ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Quantity">
                        <ItemTemplate>
                            <asp:TextBox ID="qty" runat="server" TextMode="Number" min="1" max="10" Text="1" CssClass="qty"></asp:TextBox>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Note (optional)">
                        <ItemTemplate>
                            <asp:TextBox ID="note" runat="server" MaxLength="255" placeholder="e.g. no onions"></asp:TextBox>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="">
                        <ItemTemplate>
                            <asp:Button ID="addBtn" runat="server" Text="Add to cart" CssClass="btn btn-sm"
                                CommandName="AddToCart" CommandArgument="<%# Container.DataItemIndex %>" />
                            <asp:Button ID="favBtn" runat="server" CssClass="btn btn-sm btn-secondary"
                                CommandName="Favorite" CommandArgument="<%# Container.DataItemIndex %>" />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </asp:Panel>

</asp:Content>
