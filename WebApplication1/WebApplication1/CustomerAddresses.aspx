<%@ Page Title="My addresses" Language="C#" MasterPageFile="~/Customer.master" AutoEventWireup="true" CodeBehind="CustomerAddresses.aspx.cs" Inherits="WebApplication1.CustomerAddresses" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>My addresses</h1>
    <p class="subtitle">Your active address decides which businesses you see, your cart and where orders are delivered.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- Add / edit form --%>
    <asp:Panel ID="addressForm" runat="server" CssClass="card" Visible="false">
        <h2><asp:Label ID="formTitle" runat="server"></asp:Label></h2>
        <div class="row">
            <div class="field">
                <label>Address</label>
                <asp:TextBox ID="aDescription" runat="server" MaxLength="150" placeholder="Street, building, apartment"></asp:TextBox>
            </div>
            <div class="field">
                <label>Zone</label>
                <asp:DropDownList ID="aZone" runat="server"></asp:DropDownList>
            </div>
        </div>
        <asp:Label ID="formNote" runat="server" CssClass="muted"></asp:Label>
        <div class="btn-row">
            <asp:Button ID="saveBtn" runat="server" Text="Save address" CssClass="btn" OnClick="save_Click" />
            <asp:Button ID="cancelBtn" runat="server" Text="Cancel" CssClass="btn btn-secondary" OnClick="cancel_Click" />
        </div>
    </asp:Panel>

    <div class="card">
        <div class="card-head">
            <h2>All my addresses</h2>
            <asp:Button ID="addBtn" runat="server" Text="+ Add an address" CssClass="btn" OnClick="add_Click" />
        </div>
        <asp:GridView ID="addressesGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="address_id,description,zone_id,is_active" OnRowCommand="addressesGrid_RowCommand" OnRowDataBound="addressesGrid_RowDataBound"
            EmptyDataText="You have no address yet. Add one to start ordering.">
            <Columns>
                <asp:BoundField DataField="description" HeaderText="Address" />
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Label ID="activeBadge" runat="server" CssClass="status status-Active" Text="Active"></asp:Label>
                        <asp:Button ID="activateBtn" runat="server" Text="Make active" CssClass="btn btn-sm"
                            CommandName="Activate" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="editBtn" runat="server" Text="Edit" CssClass="btn btn-sm btn-secondary"
                            CommandName="EditAddress" CommandArgument="<%# Container.DataItemIndex %>" />
                        <asp:Button ID="deleteBtn" runat="server" Text="Delete" CssClass="btn btn-sm btn-danger"
                            CommandName="DeleteAddress" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
