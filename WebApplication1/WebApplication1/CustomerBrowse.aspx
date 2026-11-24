<%@ Page Title="Browse" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerBrowse.aspx.cs" Inherits="WebApplication1.CustomerBrowse" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>Find a business</h1>
    <p class="subtitle"><asp:Label ID="addressLine" runat="server"></asp:Label></p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <asp:Panel ID="searchPanel" runat="server">
        <div class="card">
            <div class="two-cols">
                <%-- Search_Platform: by name --%>
                <div>
                    <h2>Search by name</h2>
                    <div class="row">
                        <div class="field">
                            <asp:TextBox ID="keyword" runat="server" MaxLength="100" placeholder="e.g. Pizza"></asp:TextBox>
                        </div>
                        <div class="field field-button">
                            <asp:Button ID="searchBtn" runat="server" Text="Search" CssClass="btn" OnClick="search_Click" />
                        </div>
                    </div>
                </div>
                <%-- Nearby_Businesses_By_Category: by product category --%>
                <div>
                    <h2>Browse by category</h2>
                    <div class="row">
                        <div class="field">
                            <asp:DropDownList ID="category" runat="server"></asp:DropDownList>
                        </div>
                        <div class="field field-button">
                            <asp:Button ID="browseBtn" runat="server" Text="Browse" CssClass="btn" OnClick="browse_Click" />
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <asp:Panel ID="resultsPanel" runat="server" CssClass="card" Visible="false">
            <h2><asp:Label ID="resultsTitle" runat="server"></asp:Label></h2>
            <asp:GridView ID="resultsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
                OnRowDataBound="resultsGrid_RowDataBound">
                <Columns>
                    <asp:HyperLinkField DataTextField="business_name" DataNavigateUrlFields="business_id"
                        DataNavigateUrlFormatString="~/BusinessPage.aspx?id={0}" HeaderText="Business" />
                    <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                    <asp:TemplateField HeaderText="Now">
                        <ItemTemplate><asp:Label ID="openNow" runat="server"></asp:Label></ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="avg_rating" HeaderText="Rating" DataFormatString="{0:0.0} &#9733;" NullDisplayText="No ratings yet" HtmlEncode="false" />
                    <asp:BoundField DataField="ratings_count" HeaderText="Ratings" />
                    <asp:TemplateField HeaderText="Delivery">
                        <ItemTemplate><asp:Label ID="delivery" runat="server"></asp:Label></ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </asp:Panel>
    </asp:Panel>

</asp:Content>
