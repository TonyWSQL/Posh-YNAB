function Get-Budget {
    <#
    .SYNOPSIS
    Describe the function here
    .DESCRIPTION
    Describe the function in more detail
    .EXAMPLE
    Give an example of how to use it
    .EXAMPLE
    Give another example of how to use it
    .PARAMETER computername
    The computer name to query. Just one.
    .PARAMETER logname
    The name of a file to write failed computer names to. Defaults to errors.txt.
    #>
    [CmdletBinding(DefaultParameterSetName='List')]
    param(
        [Parameter(Mandatory=$true)]
        [String]$Token,

        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName='Detail')]
        [String[]]$BudgetID,

        [Parameter(ParameterSetName='List')]
        [Switch]$ListAll
    )

    begin {
        # Set the default header value for Invoke-RestMethod
        $header =  Get-Header $Token
        $dateFormat = 'yyyy-MM-ddTHH:mm:ss+00:00'
    }

    process {
        switch ($PsCmdlet.ParameterSetName) {
            'List' {
                # Return a list of budgets if no ID is specified or if ListAvailable is supplied
                $response = Invoke-RestMethod "$uri/budgets" -Headers $header
                $budgets = $response.data.budgets
                $budgets.ForEach{
                    [PSCustomObject]@{
                        BudgetID = $_.id
                        Name = $_.name
                        'Last Modified' = [datetime]::ParseExact($_.last_modified_on, $dateFormat, $null).ToLocalTime()
                        'First Month' = $_.first_month
                        'Last Month' = $_.last_month
                        'Date Format' = $_.date_format.format
                        'Currency Format' = [Ordered]@{
                            'ISO Code' = $_.currency_format.iso_code
                            'Example Format' = $_.currency_format.example_format
                            'Decimal Digits' = $_.currency_format.decimal_digits
                            'Decimal Separator' = $_.currency_format.decimal_separator
                            'Symbol First' = $_.currency_format.symbol_first
                            'Group Separator' = $_.currency_format.group_separator
                            'Currency Symbol' = $_.currency_format.currency_symbol
                            'Display Symbol' = $_.currency_format.display_symbol
                        }
                    }
                }
            }
            'Detail' {
                # Return details of each provided BudgetID
                $BudgetID.ForEach{
                    $response = Invoke-RestMethod "$uri/budgets/$_" -Headers $header
                    $budget = $response.data.budget
                    $accounts = Get-ParsedAccountJson $budget.accounts
                    $payees = Get-ParsedPayeeJson $budget.payees $budget.payee_locations

                    [PSCustomObject]@{
                        BudgetID = $budget.id
                        Name = $budget.name
                        'Last Modified' = [datetime]::ParseExact($budget.last_modified_on, $dateFormat, $null).ToLocalTime()
                        'First Month' = $budget.first_month
                        'Last Month' = $budget.last_month
                        'Date Format' = $budget.date_format.format
                        'Currency Format' = [PSCustomObject]@{
                            'ISO Code' = $budget.currency_format.iso_code
                            'Example Format' = $budget.currency_format.example_format
                            'Decimal Digits' = $budget.currency_format.decimal_digits
                            'Decimal Separator' = $budget.currency_format.decimal_separator
                            'Symbol First' = $budget.currency_format.symbol_first
                            'Group Separator' = $budget.currency_format.group_separator
                            'Currency Symbol' = $budget.currency_format.currency_symbol
                            'Display Symbol' = $budget.currency_format.display_symbol
                        }
                        Accounts = $accounts
                        Payees = $payees
                    }
                }
            }
        }
    }
}
