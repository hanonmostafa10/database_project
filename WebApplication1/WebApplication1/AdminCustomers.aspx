<%@ Page Title="Customers and vouchers" Language="C#" MasterPageFile="~/Admin.master" AutoEventWireup="true" CodeBehind="AdminCustomers.aspx.cs" Inherits="WebApplication1.AdminCustomers" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <h1>Customers and vouchers</h1>
    <p class="subtitle">Reward customers with vouchers, and blacklist customers who break the rules.</p>

    <asp:Label ID="msg" runat="server" CssClass="msg"></asp:Label>

    <%-- 3.2 e: issue a voucher to a customer --%>
    <div class="card">
        <h2>Issue a voucher</h2>
        <div class="row">
            <div class="field">
                <label>Customer</label>
                <asp:DropDownList ID="voucherCustomer" runat="server"></asp:DropDownList>
            </div>
            <div class="field">
                <label>Promo code</label>
                <asp:TextBox ID="promoCode" runat="server" MaxLength="30" placeholder="SUMMER10"></asp:TextBox>
            </div>
        </div>
        <div class="row">
            <div class="field">
                <label>Discount type</label>
                <asp:RadioButtonList ID="discountType" runat="server" RepeatDirection="Horizontal" CssClass="radio">
                    <asp:ListItem Value="1" Selected="True">Percentage (%)</asp:ListItem>
                    <asp:ListItem Value="0">Fixed amount (EGP)</asp:ListItem>
                </asp:RadioButtonList>
            </div>
            <div class="field">
                <label>Amount <span class="hint">(1 to 100 for a percentage)</span></label>
                <asp:TextBox ID="voucherAmount" runat="server" TextMode="Number" step="0.01" min="0"></asp:TextBox>
            </div>
            <div class="field">
                <label>Expiry date</label>
                <asp:TextBox ID="expiryDate" runat="server" TextMode="Date"></asp:TextBox>
            </div>
        </div>
        <asp:Button ID="issueBtn" runat="server" Text="Issue voucher" CssClass="btn" OnClick="issue_Click" />
    </div>

    <%-- 3.2 e: all active vouchers --%>
    <div class="card">
        <h2>Active vouchers</h2>
        <asp:GridView ID="vouchersGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            EmptyDataText="There are no active vouchers.">
            <Columns>
                <asp:BoundField DataField="promo_code" HeaderText="Promo code" />
                <asp:BoundField DataField="customer_name" HeaderText="Customer" />
                <asp:BoundField DataField="discount" HeaderText="Discount" />
                <asp:BoundField DataField="expiry_date" HeaderText="Expires on" DataFormatString="{0:dd MMM yyyy}" />
            </Columns>
        </asp:GridView>
    </div>

    <%-- 3.2 f: blacklist a customer with a reason --%>
    <div class="card">
        <h2>Blacklist a customer</h2>
        <p class="muted">A blacklisted customer cannot log in. Their orders that were not picked up yet are cancelled and
            refunded, and their unused vouchers are deleted.</p>
        <div class="row">
            <div class="field">
                <label>Customer</label>
                <asp:DropDownList ID="blacklistCustomer" runat="server" ClientIDMode="Static"></asp:DropDownList>
            </div>
            <div class="field">
                <label>Reason</label>
                <asp:TextBox ID="blacklistReason" runat="server" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <asp:Button ID="blacklistBtn" runat="server" Text="Blacklist customer" CssClass="btn btn-danger" OnClick="blacklist_Click"
            OnClientClick="return confirmBlacklist();" />
    </div>

    <%-- 3.2 f: blacklisted customers; I can lift only the blacklists I set --%>
    <div class="card">
        <h2>Blacklisted customers</h2>
        <asp:GridView ID="blacklistGrid" runat="server" AutoGenerateColumns="false" CssClass="grid" GridLines="None"
            DataKeyNames="customer_id,customer_name" OnRowCommand="blacklistGrid_RowCommand" OnRowDataBound="blacklistGrid_RowDataBound"
            EmptyDataText="No customer is blacklisted.">
            <Columns>
                <asp:BoundField DataField="customer_name" HeaderText="Customer" />
                <asp:BoundField DataField="reason" HeaderText="Reason" />
                <asp:BoundField DataField="blacklisted_by" HeaderText="Blacklisted by" />
                <asp:TemplateField HeaderText="">
                    <ItemTemplate>
                        <asp:Button ID="liftBtn" runat="server" Text="Lift blacklist" CssClass="btn btn-sm"
                            CommandName="Lift" CommandArgument="<%# Container.DataItemIndex %>" />
                        <asp:Label ID="notMine" runat="server" CssClass="muted" Text="Only the admin who set it can lift it"></asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <script type="text/javascript">
        // Say what will happen before blacklisting (it cannot be undone automatically)
        function confirmBlacklist() {
            var list = document.getElementById('blacklistCustomer');
            if (list.value === '') return true; // the server asks to choose a customer
            var name = list.options[list.selectedIndex].text;
            return confirm('Blacklist ' + name + '?\n\nThey will not be able to log in, their orders that were not picked up yet '
                + 'will be cancelled and refunded, and their unused vouchers will be deleted.');
        }
    </script>

</asp:Content>
