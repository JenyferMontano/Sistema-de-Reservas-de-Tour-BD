import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ActualizarClienteUsuarioComponent } from './actualizar-cliente-usuario.component';

describe('ActualizarClienteUsuarioComponent', () => {
  let component: ActualizarClienteUsuarioComponent;
  let fixture: ComponentFixture<ActualizarClienteUsuarioComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ActualizarClienteUsuarioComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ActualizarClienteUsuarioComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
