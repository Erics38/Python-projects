class BalanceExeption(Exception):
    pass


class BankAccount:
    def __init__(self, intialAmount, acctName):
        self.balance = intialAmount
        self.name = acctName
        print(f"\nAccount '{self.name}' created. \nBalance = ${self.balance:.2f}")


    def getBalance (self):
        print(f"\nAccount '{self.name}' balance = ${self.balance:.2f}")

    def depost(self, Amount):
        self.balance = self.balance + Amount
        print(f"\nDeposit complete.")
        self.getBalance()

    def viableTransaction(self, Amount):
        if self.balance >= Amount:
            return
        else:
            raise BalanceExeption(f"\nSorry, account '{self.name}' has insuffient funds and can not withdraw '{Amount}'")
        
    def withdraw(self, Amount):
        fee = 3
        Total_amount = Amount + fee
        try:
            self.viableTransaction(Total_amount)
            self.balance = self.balance - Total_amount
            print(f"\nWithdraw complete. and there is a ${fee} fee")
            self.getBalance()
        except BalanceExeption as error:
            print(f'\nWithdraw interrupted: {error}')
    
    def transfer(self, Amount, account):
        try:
            print('\n********** \n\nBeginning Transfer....')
            self.viableTransaction(Amount)
            self.withdraw(Amount)
            account.depost(Amount)
            print('\nTransfer complete! \n\n**********')
        except BalanceExeption as error:
            print(f'\nTransfer interrupted: {error}')

class InterestRewardsAcct(BankAccount):
    def depost(self, Amount):
        self.balance = self.balance + (Amount *1.05)
        print("\nDeposit complete.")
        self.getBalance()


class SavingsAcct(InterestRewardsAcct):
    def __init__ (self, initalAmount, acctName):
        super().__init__(initalAmount, acctName)
        self.fee = 5

    def withdraw(self, Amount):
        try:    
            self.viableTransaction(Amount + self.fee)
            self.balance = self.balance - (Amount + self.fee)
            print("\nWithdraw complete")
            self.getBalance()
        except BalanceExeption as error:
            print(f"\nWithdraw interupted: {error}")

    
    

