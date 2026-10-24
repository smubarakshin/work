import { expect, test } from '@playwright/test';
import { CartPage } from '../../pages/CartPage';
import { CheckoutPage } from '../../pages/CheckoutPage';
import { InventoryPage } from '../../pages/InventoryPage';
import { LoginPage } from '../../pages/LoginPage';

test.describe('SauceDemo checkout flow', () => {
  test('completes a full purchase: login, add to cart, checkout', async ({ page }) => {
    const loginPage = new LoginPage(page);
    const inventoryPage = new InventoryPage(page);
    const cartPage = new CartPage(page);
    const checkoutPage = new CheckoutPage(page);

    await loginPage.goto();
    await loginPage.loginAsStandardUser();
    await inventoryPage.expectLoaded();

    await inventoryPage.addProductToCart('Sauce Labs Backpack');
    await inventoryPage.addProductToCart('Sauce Labs Bike Light');
    await inventoryPage.expectCartCount(2);

    await inventoryPage.openCart();
    await cartPage.expectLoaded();
    await cartPage.expectItemPresent('Sauce Labs Backpack');
    await cartPage.expectItemPresent('Sauce Labs Bike Light');
    await cartPage.checkout();

    await checkoutPage.fillInformation({
      firstName: 'John',
      lastName: 'Doe',
      postalCode: '90210',
    });
    await checkoutPage.finishCheckout();
    await checkoutPage.expectOrderComplete();
  });

  test('rejects a locked-out user with a clear error', async ({ page }) => {
    const loginPage = new LoginPage(page);

    await loginPage.goto();
    await loginPage.login('locked_out_user', 'secret_sauce');
    await loginPage.expectErrorMessage('Sorry, this user has been locked out.');
  });

  test('removing an item updates the cart', async ({ page }) => {
    const loginPage = new LoginPage(page);
    const inventoryPage = new InventoryPage(page);
    const cartPage = new CartPage(page);

    await loginPage.goto();
    await loginPage.loginAsStandardUser();
    await inventoryPage.expectLoaded();

    await inventoryPage.addProductToCart('Sauce Labs Backpack');
    await inventoryPage.expectCartCount(1);
    await inventoryPage.openCart();
    await cartPage.expectItemPresent('Sauce Labs Backpack');
    await cartPage.removeItem('Sauce Labs Backpack');
    await expect(inventoryPage.cartBadge).toHaveCount(0);
  });
});
