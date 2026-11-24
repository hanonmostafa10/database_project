<%@ Page Title="Businesses" Language="C#" MasterPageFile="~/Admin.master" AutoEventWireup="true" CodeBehind="AdminBusinesses.aspx.cs" Inherits="WebApplication1.AdminBusinesses" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>Businesses</h1>
    <p class="subtitle">Approve new businesses, suspend or reinstate them, and browse every business profile.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.2 b: businesses awaiting approval, approve or reject from the same page --%>
    <div class="card">
        <h2>Waiting for approval</h2>
        <asp:Label ID="pendingNote" runat="server" CssClass="muted"></asp:Label>
        <asp:GridView ID="pendingGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="business_id,business_name" OnRowCommand="pendingGrid_RowCommand" OnRowDataBound="pendingGrid_RowDataBound"
            EmptyDataText="No business is waiting for approval right now.">
            <Columns>
                <asp:BoundField DataField="business_name" HeaderText="Business" />
                <asp:BoundField DataField="business_type" HeaderText="Type" />
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="partner_name" HeaderText="Owner" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="approveBtn" runat="server" Text="Approve" CssClass="btn btn-sm"
                            CommandName="Approve" CommandArgument="<%# Container.DataItemIndex %>" />
                        <asp:Button ID="rejectBtn" runat="server" Text="Reject" CssClass="btn btn-sm btn-danger"
                            CommandName="Reject" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.2 c: browse all business profiles filtered by status and type, suspend an Active one --%>
    <div class="card">
        <h2>All businesses</h2>
        <div class="row">
            <div class="field">
                <label>Status</label>
                <asp:DropDownList ID="statusFilter" runat="server" AutoPostBack="true" OnSelectedIndexChanged="filter_Changed">
                    <asp:ListItem Value="">All statuses</asp:ListItem>
                    <asp:ListItem Value="Pending">Pending</asp:ListItem>
                    <asp:ListItem Value="Active">Active</asp:ListItem>
                    <asp:ListItem Value="Suspended">Suspended</asp:ListItem>
                    <asp:ListItem Value="Rejected">Rejected</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field">
                <label>Type</label>
                <asp:DropDownList ID="typeFilter" runat="server" AutoPostBack="true" OnSelectedIndexChanged="filter_Changed">
                    <asp:ListItem Value="">All types</asp:ListItem>
                    <asp:ListItem Value="Restaurant">Restaurant</asp:ListItem>
                    <asp:ListItem Value="Pharmacy">Pharmacy</asp:ListItem>
                </asp:DropDownList>
            </div>
        </div>

        <%-- Suspend form: opens when Suspend is clicked on a row --%>
        <asp:Panel ID="suspendPanel" runat="server" Visible="false" CssClass="inline-form">
            <h2>Suspend <asp:Label ID="suspendName" runat="server"></asp:Label></h2>
            <p class="muted">Suspending hides all its products, and cancels and refunds its orders that were not picked up yet.</p>
            <div class="field">
                <label>Reason for the suspension</label>
                <asp:TextBox ID="suspendReason" runat="server" TextMode="MultiLine" Rows="2" MaxLength="255"></asp:TextBox>
            </div>
            <div class="btn-row">
                <asp:Button ID="suspendConfirmBtn" runat="server" Text="Suspend business" CssClass="btn btn-danger" OnClick="suspend_Click" />
                <asp:Button ID="suspendCancelBtn" runat="server" Text="Cancel" CssClass="btn btn-secondary" OnClick="suspendCancel_Click" />
            </div>
        </asp:Panel>

        <asp:GridView ID="allGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="business_id,business_name,status,zone_name" OnRowCommand="allGrid_RowCommand" OnRowDataBound="allGrid_RowDataBound"
            EmptyDataText="No business matches these filters.">
            <Columns>
                <asp:BoundField DataField="business_name" HeaderText="Business" />
                <asp:BoundField DataField="business_type" HeaderText="Type" />
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="partner_name" HeaderText="Owner" />
                <asp:BoundField DataField="hours" HeaderText="Hours" />
                <asp:TemplateField HeaderText="Status">
                    <ItemTemplate>
                        <span class='status status-<%# Eval("status") %>'><%# Eval("status") %></span>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="suspendBtn" runat="server" Text="Suspend" CssClass="btn btn-sm btn-danger"
                            CommandName="StartSuspend" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.2 c: suspended businesses with their reasons; reinstate (Super Admin only) --%>
    <div class="card">
        <h2>Suspended businesses</h2>
        <asp:Label ID="reinstateNote" runat="server" CssClass="muted"></asp:Label>
        <asp:GridView ID="suspendedGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="business_id,business_name" OnRowCommand="suspendedGrid_RowCommand"
            EmptyDataText="No business is suspended.">
            <Columns>
                <asp:BoundField DataField="business_name" HeaderText="Business" />
                <asp:BoundField DataField="zone_name" HeaderText="Zone" />
                <asp:BoundField DataField="suspension_reason" HeaderText="Reason" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="reinstateBtn" runat="server" Text="Reinstate" CssClass="btn btn-sm"
                            CommandName="Reinstate" CommandArgument="<%# Container.DataItemIndex %>" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

</asp:Content>
