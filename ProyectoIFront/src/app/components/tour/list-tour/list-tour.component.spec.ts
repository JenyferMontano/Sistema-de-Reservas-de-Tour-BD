import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ListTourComponent } from './list-tour.component';

describe('ListTourComponent', () => {
  let component: ListTourComponent;
  let fixture: ComponentFixture<ListTourComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ListTourComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ListTourComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
