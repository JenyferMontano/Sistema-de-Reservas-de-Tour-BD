import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MisFacturasUsuarioComponent } from './mis-facturas-usuario.component';

describe('MisFacturasUsuarioComponent', () => {
  let component: MisFacturasUsuarioComponent;
  let fixture: ComponentFixture<MisFacturasUsuarioComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MisFacturasUsuarioComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MisFacturasUsuarioComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
