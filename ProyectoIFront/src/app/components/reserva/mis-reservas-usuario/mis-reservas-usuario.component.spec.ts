import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MisReservasUsuarioComponent } from './mis-reservas-usuario.component';

describe('MisReservasUsuarioComponent', () => {
  let component: MisReservasUsuarioComponent;
  let fixture: ComponentFixture<MisReservasUsuarioComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MisReservasUsuarioComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MisReservasUsuarioComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
