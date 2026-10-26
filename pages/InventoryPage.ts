import { expect, type Locator, type Page } from '@playwright/test';

export class InventoryPage {
  readonly page: Page;
  readonly title: Locator;
  readonly cartBadge: Locator;
  readonly cartLink: Locator;
  readonly sortDropdown: Locator;

  constructor(page: Page) {
    this.page = page;
    this.title = page.locator('.title');
    this.cartBadge = page.locator('.shopping_cart_badge');
    this.cartLink = page.locator('.shopping_cart_link');
    this.sortDropdown = page.locator('[data-test="product-sort-container"]');
  }

  async expectLoaded(): Promise<void> {
    await expect(this.page).toHaveURL(/.*inventory\.html/);
    await expect(this.title).toHaveText('Products');
  }

  private addToCartButton(productName: string): Locator {
    return this.page.locator('.inventory_item', { hasText: productName }).locator('button');
  }

  async addProductToCart(productName: string): Promise<void> {
    const button = this.addToCartButton(productName);
    await expect(button).toHaveText('Add to cart');
    await button.click();
    await expect(button).toHaveText('Remove');
  }

  async getCartCount(): Promise<number> {
    const text = await this.cartBadge.textContent();
    return text === null ? 0 : Number(text);
  }

  async expectCartCount(count: number): Promise<void> {
    await expect(this.cartBadge).toHaveText(String(count));
  }

  async sortByPriceLowToHigh(): Promise<void> {
    await this.sortDropdown.selectOption('lohi');
  }

  async openCart(): Promise<void> {
    await this.cartLink.click();
    await expect(this.page).toHaveURL(/.*cart\.html/);
  }
}
