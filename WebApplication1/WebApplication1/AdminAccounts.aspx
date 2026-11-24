<%@ Page Title="Admin accounts" Language="C#" MasterPageFile="~/Admin.master" AutoEventWireup="true" CodeBehind="AdminAccounts.aspx.cs" Inherits="WebApplication1.AdminAccounts" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>Admin accounts</h1>
    <p class="subtitle">Create new admins and choose the zone each Zone Admin manages.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.2 d is a Super Admin feature: the whole page is hidden for a Zone Admin --%>
    <asp:Panel ID="superAdminPanel" runat="server">

        <div class="card">
            <h2>All admins</h2>
            <asp:GridView ID="adminsGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None">
                <Columns>
                    <asp:BoundField DataField="admin_name" HeaderText="Name" />
                    <asp:BoundField DataField="username" HeaderText="Username" />
                    <asp:BoundField DataField="role" HeaderText="Role" />
                    <asp:BoundField DataField="zone_name" HeaderText="Zone" NullDisplayText="All zones" />
                </Columns>
            </asp:GridView>
        </div>

        <%-- 3.2 d: assign or move a Zone Admin to a zone --%>
        <div class="card">
            <h2>Assign a Zone Admin to a zone</h2>
            <div class="row">
                <div class="field">
                    <label>Zone Admin</label>
                    <asp:DropDownList ID="assignAdmin" runat="server"></asp:DropDownList>
                </div>
                <div class="field">
                    <label>Zone</label>
                    <asp:DropDownList ID="assignZone" runat="server"></asp:DropDownList>
                </div>
            </div>
            <asp:Button ID="assignBtn" runat="server" Text="Assign zone" CssClass="btn" OnClick="assign_Click" />
        </div>

        <%-- 3.2 d: create a new admin --%>
        <div class="card">
            <h2>Create a new admin</h2>
            <div class="row">
                <div class="field">
                    <label>Role</label>
                    <asp:DropDownList ID="newRole" runat="server" AutoPostBack="true" OnSelectedIndexChanged="newRole_Changed">
                        <asp:ListItem Value="Zone Admin">Zone Admin (manages one zone)</asp:ListItem>
                        <asp:ListItem Value="Super Admin">Super Admin (manages all zones)</asp:ListItem>
                    </asp:DropDownList>
                </div>
                <asp:Panel ID="newZonePanel" runat="server" CssClass="field">
                    <label>Zone</label>
                    <asp:DropDownList ID="newZone" runat="server"></asp:DropDownList>
                </asp:Panel>
            </div>
            <div class="row">
                <div class="field">
                    <label>First name</label>
                    <asp:TextBox ID="firstName" runat="server" MaxLength="30"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Middle name <span class="hint">(optional)</span></label>
                    <asp:TextBox ID="middleName" runat="server" MaxLength="30"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Last name</label>
                    <asp:TextBox ID="lastName" runat="server" MaxLength="30"></asp:TextBox>
                </div>
            </div>
            <div class="row">
                <div class="field">
                    <label>Username</label>
                    <asp:TextBox ID="newUsername" runat="server" MaxLength="30"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Password</label>
                    <asp:TextBox ID="newPassword" runat="server" TextMode="Password" MaxLength="30"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Repeat password</label>
                    <asp:TextBox ID="confirmPassword" runat="server" TextMode="Password" MaxLength="30"></asp:TextBox>
                </div>
            </div>
            <div class="row">
                <div class="field">
                    <label>Email</label>
                    <asp:TextBox ID="email" runat="server" TextMode="Email" MaxLength="100"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Phone <span class="hint">(optional, 11 digits)</span></label>
                    <asp:TextBox ID="phone" runat="server" MaxLength="11"></asp:TextBox>
                </div>
                <div class="field">
                    <label>Date of birth <span class="hint">(optional)</span></label>
                    <asp:TextBox ID="dob" runat="server" TextMode="Date"></asp:TextBox>
                </div>
            </div>
            <asp:Button ID="createBtn" runat="server" Text="Create admin" CssClass="btn" OnClick="create_Click" />
        </div>
    </asp:Panel>

</asp:Content>
