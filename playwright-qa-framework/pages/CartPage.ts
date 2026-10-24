import { expect, type Locator, type Page } from '@playwright/test';

export class CartPage {
  readonly page: Page;
  readonly title: Locator;
  readonly checkoutButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.title = page.locator('.title');
    this.checkoutButton = page.locator('[data-test="checkout"]');
  }

  async expectLoaded(): Promise<void> {
    await expect(this.page).toHaveURL(/.*cart\.html/);
    await expect(this.title).toHaveText('Your Cart');
  }

  private cartItem(productName: string): Locator {
    return this.page.locator('.cart_item', { hasText: productName });
  }

  async expectItemPresent(productName: string): Promise<void> {
    await expect(this.cartItem(productName)).toBeVisible();
  }

  async removeItem(productName: string): Promise<void> {
    await this.cartItem(productName).locator('button').click();
    await expect(this.cartItem(productName)).toHaveCount(0);
  }

  async checkout(): Promise<void> {
    await this.checkoutButton.click();
    await expect(this.page).toHaveURL(/.*checkout-step-one\.html/);
  }
}
