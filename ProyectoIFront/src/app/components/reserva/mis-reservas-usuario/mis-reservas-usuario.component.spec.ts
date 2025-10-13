import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MisReservasHuespedComponent } from './mis-reservas-usuario.component';

describe('MisReservasHuespedComponent', () => {
  let component: MisReservasHuespedComponent;
  let fixture: ComponentFixture<MisReservasHuespedComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MisReservasHuespedComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MisReservasHuespedComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
