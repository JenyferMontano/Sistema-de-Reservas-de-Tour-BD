import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BuscarReservaHuespedComponent } from './buscar-reserva-huesped.component';

describe('BuscarReservaHuespedComponent', () => {
  let component: BuscarReservaHuespedComponent;
  let fixture: ComponentFixture<BuscarReservaHuespedComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BuscarReservaHuespedComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(BuscarReservaHuespedComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
